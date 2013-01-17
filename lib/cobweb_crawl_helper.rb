# The crawl class gives easy access to information about the crawl, and gives the ability to stop a crawl
class CobwebCrawlHelper
  
  attr_accessor :id
  
  BATCH_SIZE = 200
  FINISHED = "Finished"
  STARTING = "Starting"
  CANCELLED = "Cancelled"
  
  def initialize(data)
    @data = data
    
    # TAKING A LONG TIME TO RUN ON PRODUCTION BOX
    @stats = Stats.new(data)
  end
  
  def destroy(options={})
    
    options[:queue_name] = "cobweb_crawl_job" unless options.has_key?(:queue_name)
    options[:finished_resque_queue] = CobwebFinishedJob unless options.has_key?(:finished_resque_queue)
    
    if options[:finished_resque_queue]
      Resque.enqueue(options[:finished_resque_queue])
    end
    
    position = Resque.size(options[:queue_name])
    until position == 0
      position-=BATCH_SIZE
      position = 0 if position < 0
      job_items = Resque.peek(options[:queue_name], position, BATCH_SIZE)
      job_items.each do |item|
        if item["args"][0]["crawl_id"] == id
          # remove this job from the queue
          Resque.dequeue(SpiderJob, item["args"][0])
        end
      end
    end
    
  end
  
  def statistics
    @stats
  end
  
  def status
    statistics.get_status
  end
  
  def id
    @data[:crawl_id]
  end
  
end
