require 'resque'
require 'resque/batched_job'

class SpiderJob

  @queue = :cobweb_crawl_job
  
  def self.perform(content_request)

    crawl = SimpleCrawl.new(content_request)
    
    if crawl.retrieve
      puts "enqueuing urls for workers" 
      enqueue_urls(crawl.urls, content_request, crawl)
    else
      # Failed to start the crawling process for whatever reason, so
      # we complete the job. There will be no results for the site however
      puts "Error beginning crawl!" 

      QueueManager.queue_job(content_request[:crawl_finished_queue], content_request)

    end

  end

  def self.enqueue_urls(urls, content_request, crawl)
    queued = []
    batch_id = content_request[:crawl_id]

    if (crawl.robot)
      urls = crawl.robot.filtered_urls(urls)
    end
    
    urls.each do |url|
      content_request[:retrieve_url] = url
      
      queued << QueueManager.queue_batch_job(content_request[:processing_queue], batch_id, content_request)
    end

    queued.all?
  end
  
end
