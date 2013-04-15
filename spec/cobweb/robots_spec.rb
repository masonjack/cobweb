require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Robots do

  before(:each) do
    @cobweb = Cobweb.new :quiet => true, :cache => nil
  end
  
  describe "default user-agent" do
    before(:each) do
      @options = {:url => "http://localhost:3532/"}
    end
    
    it "should parse a valid robots.txt" do
      lambda {Robots.new(@options)}.should_not raise_error
    end
    
    it "should allow urls marked as allow" do
      robot = Robots.new(@options)
      robot.allowed?("http://localhost:3532/globalmarketfinder/asdf.html").should be_true
    end
    it "should disallow urls specified as disallow" do
      robot = Robots.new(@options)
      robot.allowed?("http://localhost:3532/globalmarketfinder/").should be_false
      robot.allowed?("http://localhost:3532/globalmarketfinder/asdf").should be_false
    end
    it "should allow urls not listed" do
      robot = Robots.new(@options)
      robot.allowed?("http://localhost:3532/notlistedinrobotsfile").should be_true
    end
     
  end
  
  describe "google user-agent" do
    before(:each) do
      @options = {:url => "http://localhost:3532/", :user_agent => "google"}
    end
    it "should parse a valid robots.txt" do
      lambda {Robots.new(@options)}.should_not raise_error
    end
    
    it "should disallow all urls" do
      robot = Robots.new(@options)
      #robot.allowed?("http://localhost:3532/globalmarketfinder/asdf.html").should be_false
      robot.allowed?("http://localhost:3532/globalmarketfinder/").should be_false
      robot.allowed?("http://localhost:3532/globalmarketfinder/asdf").should be_false
      robot.allowed?("http://localhost:3532/notlistedinrobotsfile").should be_false
    end
    
  end
    
  describe "cybermapper user-agent" do
    before(:each) do
      @options = {:url => "http://localhost:3532/", :user_agent => "cybermapper"}
    end
    it "should parse a valid robots.txt" do
      lambda {Robots.new(@options)}.should_not raise_error
    end
    
    it "should disallow all urls" do
      robot = Robots.new(@options)
      robot.allowed?("http://localhost:3532/globalmarketfinder/asdf.html").should be_true
      robot.allowed?("http://localhost:3532/globalmarketfinder/").should be_true
      robot.allowed?("http://localhost:3532/globalmarketfinder/asdf").should be_true
      robot.allowed?("http://localhost:3532/notlistedinrobotsfile").should be_true
    end
    
  end

  describe "filtering urls for crawling" do
    before(:each) do
      @options = {:url => "http://localhost:3532/"}
    end

    it "should filter a list of urls to allow urls correctly" do
      urls = ["http://localhost:3532/globalmarketfinder/asdf", "http://localhost:3532/globalmarketfinder/", "http://localhost:3532/notlisted"]
      robot = Robots.new(@options)
      filtered = robot.filtered_urls(urls)
      puts filtered
      filtered.size.should == 1
      filtered.include?("http://localhost:3532/globalmarketfinder/asdf").should be_false
      filtered.include?("http://localhost:3532/notlisted").should be_true
    end
    
  end
  
end
