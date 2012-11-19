require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe RedisCacheManager do

  before(:each) do
    @local_redis = {:host => "127.0.0.1", :port => 6379, :cache => 300}
    @cache = RedisCacheManager.new(@local_redis)
  end

  describe "checking items in the cache" do
    it "should return nothing when nothing in the cache" do
      @cache.in_cache?("bob").should == false
    end

    it "should allow an object to be put into the cache and confirm it exists" do
      obj = {:time => Time.now.to_s, :test => true}
      @cache.store("test", obj)
      @cache.in_cache?("test").should == true
    end

    it "should allow an object to be put into the cache and get it out again" do
      obj = {:time => Time.now.to_s, :test => true}
      @cache.store("test", obj)
      @cache.get("test").should == obj
    end
    
    
  end
  
  
  
  
end
