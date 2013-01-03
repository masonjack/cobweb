require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe SimpleCrawl do

  before(:each) do
    @options = {
      :url => "http://localhost:3532/",
      :crawl_limit_by_page => false,
      :crawl_limit => 100,
      :cache_manager => "DummyCache"
    }
    @options[:internal_urls] = []
    uri = Addressable::URI.parse(@options[:url])
    @options[:internal_urls] << [uri.scheme, "://", uri.host, ":", uri.inferred_port, "/*"].join
    
  end
  
  it "should collect all urls from a page" do
    @options[:depth] = 0
    crawl = SimpleCrawl.new(@options)
    crawl.retrieve.should be_true
    crawl.urls.size.should eql 70
  end

  it "should follow links until the queue reachs the maximum size" do
    crawl = SimpleCrawl.new(@options)
    crawl.retrieve.should be_true
    crawl.urls.size.should eql 100
  end

  it "should return a unique list of urls with no duplicates" do
    crawl = SimpleCrawl.new(@options)
    crawl.retrieve.should be_true
    crawl.urls.size.should eql 100

    puts "--------"
    puts crawl.urls
    puts "--------"
    
    check_urls = []
    counter = 1
    crawl.urls.each do |u|
      counter += 1
      puts "adding #{u}"
      if check_urls.include? u        
        fail "duplicate found at #{check_urls.index(u)} - count #{counter}" 
      end
      
      check_urls << u
    end
    
  end

  context "Error cases" do

    it "should stop crawling when dns errors occur" do
      @options[:url] = "http://www.efsdephox.com"
      crawl = SimpleCrawl.new(@options)
      crawl.retrieve.should be_false
    end
    
    
  end
  
  
  
end
