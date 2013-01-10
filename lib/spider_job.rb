require 'resque'
require 'resque/batched_job'

class SpiderJob

  @queue = :cobweb_crawl_job
  
  def self.perform(content_request)

    crawl = SimpleCrawl.new(content_request)
    if crawl.retrieve
      enqueue_urls(crawl.urls, content_request)
    else
      # Failed to start the crawling process for whatever reason, so
      # we complete the job. There will be no results for the site however
      puts "Error beginning crawl!" 
      processing_clazz = Object::const_get(content_request[:crawl_finished_queue])      
      Resque.enqueue(processing_clazz, content_request)
    end

  end

  def self.enqueue_urls(urls, content_request)
    processing_clazz = Object::const_get(content_request[:processing_queue])
    queued = []
    batch_id = content_request[:crawl_id]
    
    urls.each do |url|
      content_request[:retrieve_url] = url
      
      queued << Resque.enqueue_batched_job(processing_clazz, batch_id, content_request)
    end

    queued.all?
  end
  
end
