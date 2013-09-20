# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContentProcessor do

  
  context "When performing Character Set detection" do

    before(:each) do
      @headers = {}
      @headers["content-type"] = "text/html; charset=utf-8"
    end

    it "should return the expected UTF8 character set" do
      utf8 = File.dirname(__FILE__) + '/../samples/encoding_samples/utf-8.html'
      s = File.open(utf8) { |f| f.read }
      # result = CharDet.detect(s)
      # result.should eql 'UTF-8'
      s.encoding.name.should == "UTF-8"
      # subject = ContentProcessor.determine_content_type(s, @headers)
      # subject.character_set.should eql "UTF-8"
      
    end

    pending "should return the expected windows-1252 character set" do
      win1252 = File.dirname(__FILE__) + '/../samples/encoding_samples/windows-1252.html'
      s = File.open(win1252, 'rb') { |f| f.read }
      s.encoding.name.should == "WINDOWS-1252"
      
      subject = ContentProcessor.determine_content_type(s, @headers)
      subject.character_set.should eql "windows-1252"
      
    end

    pending "should return the expected iso-2022-7bit character set" do
      
      iso7b = File.dirname(__FILE__) + '/../samples/encoding_samples/iso-8859-9.html'
      s = File.open(iso7b, 'rb') { |f| f.read }
      
      subject = ContentProcessor.determine_content_type(s, @headers)
      subject.character_set.should eql "iso-8809-9"
      
    end

    
  end

  context "when converting" do
    before(:each) do
      @headers = {}
      @headers["content-type"] = "text/html; charset=utf-8"
    end

    pending "should convert from another encoding into utf8" do
      win1252 = File.dirname(__FILE__) + '/../samples/encoding_samples/windows-1252.html'
      s = File.open(win1252, 'rb') { |f| f.read }
      
      subject = ContentProcessor.determine_content_type(s, @headers)
      #subject.character_set.should eql "ISO-8859-1"

      converted = subject.convert_to_utf8(s)
      converted.encoding.name.should == "UTF-8"
    end
    
  end


  context "when detecting body content mime-type" do
    before(:each) do
      @headers = {}
    end
    
    it "should detect 'text/html' in simple non header related document" do
      doc = "kajsdjkfasdkjfdshkjafsdjkhjkafdskjhafsd<   body onclick='something'> </body>"
      subject = ContentProcessor.determine_content_type(doc, @headers)
      subject.mime_type.should == "text/html"
      
    end

    it "should detect 'application/octet-stream' in a bad doc" do
      doc = "kajsdjkfasdkjfdshkjafsdjkhjkafdskjhafsd<   bdy onclick='something'> </bod>"
      subject = ContentProcessor.determine_content_type(doc, @headers)
      subject.mime_type.should == "application/octet-stream"
    end
    
  end
  
end
