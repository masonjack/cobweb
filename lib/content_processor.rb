# encoding: utf-8

class ContentProcessor

  attr_reader :mime_type
  attr_reader :content_type
  attr_reader :character_set
  
  def self.determine_content_type(content, headers)
    new(header_content_type(headers), content)
    
  end

  def self.header_content_type(headers)
    
    mime_type = headers["content-type"].split(";")[0].strip
    ct = headers["content-type"]
    
    if ct.include?(";")
      charset = ct[ct.index(";")+2..-1] if !ct.nil? and ct.include?(";")
      charset = charset[charset.index("=")+1..-1] if charset and charset.include?("=")
      character_set = charset
    end

    [mime_type, character_set]
  end


  def initialize(initial_detection, content)
    @mime_type = initial_detection[0]
    
    @character_set = initial_detection[1]

    validate_character_encoding(content)
  end

  def validate_character_encoding(content)
    #puts content
    # cd = CharDet.detect(content)
    # encoding = cd['encoding']
    # confidence = cd['confidence']

    # # if confidence > 0.4
    # unless encoding == @character_set
    #   # prefer the body content detection rather than using the header
    #   # provided information
    #   @character_set = encoding
    # end
    # end
    
    
  end
  
  
  
end

