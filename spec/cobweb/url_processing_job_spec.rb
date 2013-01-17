require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SpiderJob do

  class DummySpecProcessor
    def self.perform(content)
      content.should_not == nil
    end
  end
  
  
  before(:each) do
    Resque.stub!(:enqueue).and_return(true)
    @options = {
      :url => "http://localhost:3532/",
      :crawl_limit_by_page => false,
      :crawl_limit => 100,
      :cache_manager => DummyCache.new,
      :url_processor => "DummySpecProcessor",
      :direct_call_process_job => true
    }
    @options[:internal_urls] = []
    uri = Addressable::URI.parse(@options[:url])
    @options[:internal_urls] << [uri.scheme, "://", uri.host, ":", uri.inferred_port, "/*"].join
    
  end
  

  it "should process data" do
    puts @options
    UrlProcessingJob.perform(@options)
  end
    

  
end
