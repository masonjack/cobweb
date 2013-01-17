require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SpiderJob do

  before(:each) do
    Resque.stub!(:enqueue).and_return(true)
    @options = {
      :url => "http://localhost:3532/",
      :crawl_limit_by_page => false,
      :crawl_limit => 100,
      :cache_manager => "DummyCache",
      :processing_queue => "UrlProcessingJob"
    }
    @options[:internal_urls] = []
    uri = Addressable::URI.parse(@options[:url])
    @options[:internal_urls] << [uri.scheme, "://", uri.host, ":", uri.inferred_port, "/*"].join
    
  end
  

  describe "Performing a spider job enqueus urls into Resque" do
    before(:each) do
      Resque.stub!(:enqueue).and_return(true)

    end
    
    it "should queue the items into Resque" do
      SpiderJob.perform(@options).should == true
    end
    
  end


  describe "using a real configuration" do
    before(:each) do
      @real_options = {"crawl_id"=>"f6f4502b2d73056857933225a1f26b98cf8fbd03", "url"=>"http://localhost:3532/", "crawl_limit"=>100, "quiet"=>false, "debug"=>false, "cache"=>nil, "use_encoding_safe_process_job"=>false, "follow_redirects"=>true, "redirect_limit"=>10, "processing_queue"=>"UrlProcessingJob", "crawl_finished_queue"=>"CobwebFinishedJob", "url_processor"=>"CobwebNullUrlProcessor", "timeout"=>10, "redis_options"=>{}, "internal_urls"=>["http://localhost/*", "http://localhost:3532/*"], "first_page_redirect_internal"=>true, "text_mime_types"=>["text/*", "application/xhtml+xml"], "obey_robots"=>false, "user_agent"=>"cobweb/0.0.75 (ruby/1.9.3 nokogiri/1.5.0)", "valid_mime_types"=>["*/*"], "cache_manager"=>"RedisCacheManager", "crawl_limit_by_page"=>false}
    end
    
    
    it "should correctly start a crawl" do
      SpiderJob.perform(@real_options).should == true
    end
    
  end
  
  
end
