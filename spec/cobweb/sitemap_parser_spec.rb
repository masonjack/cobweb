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
      puts sitemap.class.to_s
      sitemap.kind_of?(CobwebSitemap::XmlSitemap).should be_true
    end
    
    
    pending "should fail a badly formatted sitemap.xml file" do
    end

  end

  context "Sitemap construction" do
    before(:each) do
      @host = "http://localhost:3532/index1.html"
      @subject = SitemapParser.new(@host)
    end

    
    it "should build a sitemap with urls available when file is present and valid" do
      sitemap = @subject.build
      sitemap.urls.length.should == 2
      sitemap.urls.first.url.should == "http://www.example.com/"
    end
    
  end

  context "Nested sitemaps" do
    it "should read and build a sitemap array using a nested sitemap file" do
      
    end
    
  end
  
  
end

