require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LocalFilePersistanceProcessor do


  context "Basic file persistance" do
    it "saves files in the directory structure provided via url" do
      url = "http://en.wikipedia.org/wiki/Appalachia"
      content = {
        :url => url,
        :body => "this is the content of the file",
        :crawl_id => "12334"
      }
      time = Time.now
      LocalFilePersistanceProcessor.perform(content)
      File.exists?("#{Dir.home}/temp/en.wikipedia.org/#{time.year}/#{time.month}/#{time.day}/12334/wiki/Appalachia").should == true
    end
  end
  
  
end
