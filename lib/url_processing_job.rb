
class UrlProcessingJob

  extend Resque::Plugins::BatchedJob
  
  @queue = :cobweb_content_processing

  def self.perform(bid, content_options)
    # fetch the content
    options = HashUtil.deep_symbolize_keys(content_options)
    # We allow all the items in the batch to fail at the moment. This
    # means that the end of processing job will still be fired even if
    # all the url_processing_jobs fails
    @acceptable_failure_count = options[:crawl_limit]

    processor = Cobweb.new(content_options)
    
    url = options[:retrieve_url]
    puts "url to be processed is #{url}"
    
    content = processor.get( url, options)
    content_to_send = content_options.merge(content)

    # When a processor returns a value, this means that a
    # SignalException was raised while processing. THis is a signal
    # from the queueing mechanism that the worker in intended to
    # shutdown. Thus we need to cleanup and put this job back on the
    # queue to be restarted by anther worker - Resolves GALAXY-784
    if start_processor(options[:url_processor], content_to_send).kind_of? SignalException
      QueueManager.requeue_job(self, bid, content_options)
    end
    

    if(content_options[:additional_url_processors])
      content_options[:additional_url_processors].each do |processor|
        start_processor(processor, content_to_send)
      end
    end
    
  end

  
  def self.after_batch_finalization(bid, *args)
    content_options = args[0]
    clazz = const_get(content_options[:crawl_finished_queue])
    Resque.enqueue(clazz, *args)
  end
  

  def self.start_processor(klass_name, content)
    clazz = const_get(klass_name, content)
    ret_val = nil
    
    if(clazz.respond_to? :perform)
      ret_val =  clazz.perform(content)
    else
      raise "Supplied url_processor class does not respond to perform method"
    end

    ret_val
  end




  # helper methods 
  def self.last_working_job?(crawl_id)
    working = Resque::Worker.working
    jobs = []
    
    if working.size > 0
      joblist =  working.map(&:job)
      jobs = joblist.select do |j|
        job = j["payload"]
        if job
          if job["class"] == self.name
            job["args"][1]["crawl_id"] == crawl_id
          end
        end
      end
    end
    return true if jobs.size == 1    
    
    false
  end
  
  def self.queued_jobs_remain?(crawl_id)
    payloads = []
    index = 0

    queue_size = Resque.size(@queue)
    if queue_size > 0
      while (payload = Resque.redis.lindex("queue:#{@queue}", index)) do
        h_payload = JSON.parse(payload)
        crawl_args = h_payload["args"][1]
        if crawl_args
          payloads << crawl_args["crawl_id"]
        else
          payload << nil
        end
        index += 1
      end
    else
      return false
    end
    
    payloads.include?(crawl_id)
  end

  def self.in_progress?(crawl_id)
    unless queued_jobs_remain?(crawl_id)
      return false if last_working_job?(crawl_id)
      true
    else
      return true
    end
    
    
  end
  
end
