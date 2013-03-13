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
    
  end

  context "With gziped sitemaps" do

    pending "should extract urls from a gziped sitemap"

    pending "should extract urls from a gziped siteindex that contains multiple sitemap references"

    pending "should extract urls from siteindex that contains gziped sitemaps" 
    
  end
  
  
  
end

