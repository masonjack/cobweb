require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SitemapParser do


  context "Sitemap finding and initialization basics" do

    before(:each) do
      @host = "http://localhost:3532/index1.html"
      @subject = SitemapParser.new(@host)
    end
    
    it "should determine the location of the sitemap file" do
      location = @subject.location
      location.should == "http://localhost:3532/sitemap.xml"      
    end
        
      
    it "should build an xml sitemap when using one" do
      sitemap = @subject.build
      map = sitemap.first
      map.kind_of?(CobwebSitemap::XmlSitemap).should be_true
    end
    
    
  end

  context "Sitemap construction" do
    before(:each) do
      @host = "http://localhost:3532/index1.html"
      @subject = SitemapParser.new(@host)
    end

    
    it "should build a sitemap with urls available when file is present and valid" do
      sitemap = @subject.build
      map = sitemap.first
      map.urls.length.should == 2
      map.urls.first.url.should == "http://www.example.com/"
    end
    
  end

  context "With Nested sitemaps" do
    it "should read and build a sitemap array using a nested sitemap file" do
      subject = SitemapParser.new("http://localhost:3532/nested-sitemap.xml", true)
      maps = subject.build
      maps.length.should == 2
      maps.first.urls.length.should == 2
    end


    it "should condense multiple sitemaps into a single result" do
      subject = SitemapParser.new("http://localhost:3532/nested-sitemap.xml", true)
      maps = subject.build
      result = subject.condense
      result.urls.length.should == 2
    end

    it "should retrieve the raw url strings from a url object collection" do
      subject = SitemapParser.new("http://localhost:3532/nested-sitemap.xml", true)
      maps = subject.build
      result = subject.condense

      raw = subject.raw_urls(result)
      raw.each { |u| u.respond_to?(:concat).should be_true }
    end
    

    it "should limit the total number of urls to the limit specified across multiple sitemaps" do
      subject = SitemapParser.new("http://localhost:3532/large-nested-sitemap.xml", true)
      maps = subject.build(5)
      m = subject.condense
      m.urls.size.should == 5
      pending "not yet implemented"
    end
    
  end

  context "Huge sitemap files" do
    before(:each) do
      @big_subject = SitemapParser.new("http://localhost:3532/detailed-sitemap.xml", true)
    end
    
    it "should parse correctly" do
      result = @big_subject.build
      map = result.first
      map.urls.length.should == 10000
    end


    it "should limit the number of urls to the limit specified" do
      result = @big_subject.build(1000)
      map = result.first
      map.urls.length.should == 1000
    end
    
  end

  context "whacky sitemaps at sprint" do
    before(:each) do
      @sprint = SitemapParser.new("https://shop.sprint.com/sitemap.xml", true)
      
    end


    it "should download and parse correctly" do
      maps = @sprint.build
      m = @sprint.condense
      m.urls.size.should == 2577
    end
  end
  

  context "With gziped sitemaps" do

    pending "should extract urls from a gziped sitemap"
    "not implemented yet"


    pending "should extract urls from a gziped siteindex that contains multiple sitemap references"

    pending "should extract urls from siteindex that contains gziped sitemaps" 
    
  end
  
  
  
end

