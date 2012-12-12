
class UrlProcessingJob

  @queue = :cobweb_content_processing

  def self.perform(content_options)

    # fetch the content
    options = HashUtil.deep_symbolize_keys(content_options)
    processor = Cobweb.new(content_options)
    
    url = options[:retrieve_url]
    puts "url to be processed is #{url}"
    
    content = processor.get( url, options)
    content_to_send = content_options.merge(content)

    start_processor(options[:url_processor], content_to_send)

    if(content_options[:additional_url_processors])
      content_options[:additional_url_processors].each do |processor|
        start_processor(processor, content_to_send)
      end
    end
    
    # check if there is any other items on the queue,
    # if there is not, we are done!
    if(!in_progress?(content[:crawl_id]))
      clazz = const_get(content_options[:crawl_finished_queue])
      Resque.enqueue(clazz, content_options)
    end
    
  end


  def self.start_processor(klass_name, content)
    clazz = const_get(klass_name, content)
    
    if(clazz.respond_to? :perform)
      clazz.perform(content)
    else
      raise "Supplied url_processor class does not respond to perform method"
    end
  end


  def self.currently_running(crawl_id)

    jobs = Resque::Worker.working.map(&:job).map do |j|
      j["payload"]["args"][0]["crawl_id"] if j["payload"]["class"] == self.name
    end
    jobs.include?(crawl_id) && jobs.size > 1
  end

  def self.queued_jobs_remain?(crawl_id)
    payloads = []
    index = 0;
    while (payload = Resque.redis.lindex("queue:#{@queue}", index)) do
      h_payload = JSON.parse(payload)
      payloads << h_payload["args"][0]["crawl_id"]
      index +=1
    end
    
    payloads.include?(crawl_id)
  end

  def self.in_progress?(crawl_id)
    currently_running(crawl_id) || queued_jobs_remain?(crawl_id)
  end
  
end
