require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


class Requester
  include CobwebRequest
  attr_accessor :options

  def initialize
    @options = {}
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
      :debug                        => true,
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
      content = @requester.request("http://www.google.com.au", :get, DummyCache.new(nil), @default_opts )
      content[:body].should =~ /.*body.*/ 
    end

    it "when a DNS resolution error occurs, should handle it gracefully" do
      content = @requester.request("http://www.eephox.com", :head, DummyCache.new(nil), @default_opts)
      content[:mime_type].should eql "error/dnslookup"
      content[:error].should == "Could not resolve hostname"
    end

    it "should return 404 for the error code when nonexistant page is requested" do
      content = @requester.request("http://www.ephox.com/cobweb_dummy_request.jspd", :get, DummyCache.new(nil), @default_opts)
      content[:status_code].should eql 404
    end


    it "should stop redirecting after 10 redirects. Should also not use typhoeus redirect code" do
      content = @requester.request("http://localhost:3532/redirect-request.html", :get, DummyCache.new(nil), @default_opts)
      content[:status_code].should == 200
    end

    it "should respond with cookies to a server that requests them" do
      content = @requester.request("http://shop.sprint.com/mysprint/shop_landing.jsp?pagename=whysprint&INTNAV=ATG:HE:WS",
                                   :get,
                                   DummyCache.new(nil),
                                   @default_opts)
      content[:status_code].should == 200

    end
    
  end

  describe "head requests " do

    it "should return valid head data for a head request" do
      content = @requester.request("http://www.google.com", :head, DummyCache.new(nil), @default_opts)
      #content[:url].should eql "http://oldnavy.gap.com/buy/shopping_bag.do"
      puts content
      content[:mime_type].should eql "text/html"
      content[:status_code].should eql 200
      content[:character_set].should eql "US-ASCII"
    end
    
    it "should return 404 for the error code when nonexistant page is requested with head" do
      content = @requester.request("http://www.ephox.com/cobweb_dummy_request.jspd", :head, DummyCache.new(nil), @default_opts)
      content[:status_code].should eql 404
    end

    
  end
  

  #descr

  
end
