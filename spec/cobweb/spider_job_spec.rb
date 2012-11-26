require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SpiderJob do

  before(:each) do
    Resque.stub!(:enqueue).and_return(true)
    @options = {
      :url => "http://localhost:3532/",
      :crawl_limit_by_page => false,
      :crawl_limit => 100,
      :cache_manager => DummyCache.new,
      :processing_queue => "SpiderJob"
    }
    @options[:internal_urls] = []
    uri = Addressable::URI.parse(@options[:url])
    @options[:internal_urls] << [uri.scheme, "://", uri.host, ":", uri.inferred_port, "/*"].join

  end
  

  describe "Performing a spider job enqueus urls into Resqueue" do
    Resque.should_recieve(:enqueue).exactly(100).times
    SpiderJob.perform(@options)
    
  end
  
end
