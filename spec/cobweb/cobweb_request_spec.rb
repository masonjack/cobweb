require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class Requester
  include CobwebRequest
end

class DummyCache
  include CacheManager
  def get(key)
    nil
  end
  def set(key,value)
  end
  def in_cache?(key)
    false
  end
end


describe Cobweb do

  before(:each) do
    @requester = Requester.new
    @base_url = "http://www.baseurl.com/"
    @default_opts = {
      :use_encoding_safe_process_job =>  false,
      :follow_redirects             =>  true,
      :redirect_limit               =>   10,
      :processing_queue             => "CobwebProcessJob",
      :crawl_finished_queue         =>   "CobwebFinishedJob",
      :quiet                        => true,
      :debug                        => false,
      :cache                        => 300,
      :timeout                      => 10,
      :redis_options                =>  Hash.new,
      :internal_urls                =>  [],
      :first_page_redirect_internal =>   true,
      :text_mime_types              => ["text/*", "application/xhtml+xml"],
      :obey_robots                  => false,
      :user_agent                   =>  "cobweb/#{Cobweb.version} (ruby/#{RUBY_VERSION} nokogiri/#{Nokogiri::VERSION})",
      :valid_mime_types             =>  ["*/*"]
    }

  end
  
  it "should generate a cobweb object" do
    Requester.new.should be_an_instance_of Requester
  end



  describe "uses correct request classes for data retrieval" do
    
    # Typhoeus::Request
  end
  
  
  describe "real get requests" do

    it "should return real data" do
      content = @requester.request("http://www.google.com.au", :get, DummyCache.new, @default_opts )
      content[:body].should =~ /asdf/ 
    end
    
  end


  #descr

  
end
