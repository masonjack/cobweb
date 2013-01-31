# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContentProcessor do

  before(:each) do
    @headers = {}
    @headers["content-type"] = "text/html; charset=utf-8"
  end
  
  context "When performing Character Set detection" do

    it "should return the expected UTF8 character set" do
      utf8 = File.dirname(__FILE__) + '/../samples/encoding_samples/utf-8.html'
      s = File.open(utf8) { |f| f.read }
      # result = CharDet.detect(s)
      # result.should eql 'UTF-8'
      s.encoding.name.should == "UTF-8"
      # subject = ContentProcessor.determine_content_type(s, @headers)
      # subject.character_set.should eql "UTF-8"
      
    end

    it "should return the expected windows-1252 character set" do
      win1252 = File.dirname(__FILE__) + '/../samples/encoding_samples/windows-1252.html'
      s = File.open(win1252, 'rb') { |f| f.read }
      s.encoding.name.should == "WINDOWS-1252"
      
      subject = ContentProcessor.determine_content_type(s, @headers)
      subject.character_set.should eql "windows-1252"
      
    end

    it "should return the expected iso-2022-7bit character set" do
      
      iso7b = File.dirname(__FILE__) + '/../samples/encoding_samples/iso-8859-9.html'
      s = File.open(iso7b, 'rb') { |f| f.read }
      
      subject = ContentProcessor.determine_content_type(s, @headers)
      subject.character_set.should eql "iso-8809-9"
      
    end

    
  end

  context "when converting" do
    it "should convert from another encoding into utf8" do
      win1252 = File.dirname(__FILE__) + '/../samples/encoding_samples/windows-1252.html'
      s = File.open(win1252, 'rb') { |f| f.read }
      
      subject = ContentProcessor.determine_content_type(s, @headers)
      #subject.character_set.should eql "ISO-8859-1"

      converted = subject.convert_to_utf8(s)
      converted.encoding.name.should == "UTF-8"

      
    end
    
  end
  
end
