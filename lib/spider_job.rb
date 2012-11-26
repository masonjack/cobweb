require 'resque'


class SpiderJob

  def self.perform(content_request)

    crawl = SimpleCrawl.new(content_request)
    if crawl.retrieve
      enqueue_urls(crawl.urls, content_request)
    end
    
    
  end

  def self.enqueue_urls(urls, content_request)
    processing_clazz = const_get(content_request[:processing_queue])
    urls.each do |url|
      content_request[:retrive_url] = url
      Resque.enqueue(processing_clazz, content_request)
    end
    
  end
  
end
