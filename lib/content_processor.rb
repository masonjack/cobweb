# encoding: utf-8
#require 'charlock_holmes'

class ContentProcessor

  attr_reader :mime_type
  attr_reader :content_type
  attr_reader :character_set
  attr_reader :converted_content
  
  def self.determine_content_type(content, headers)
    new(header_content_type(headers), content)
    
  end

  def self.header_content_type(headers)
    return [nil, nil] if headers.size == 0
    
    ct = headers_access(headers, "content-type")
    mime_type = ct.split(";")[0].strip if ct
    
    if ct.include?(";")
      charset = ct[ct.index(";")+2..-1] if !ct.nil? and ct.include?(";")
      charset = charset[charset.index("=")+1..-1] if charset and charset.include?("=")
      character_set = charset
      
    end

    [mime_type, character_set]
  end


  # work around bug in typhoeus until fix is finalized
  # https://github.com/typhoeus/typhoeus/issues/227
  def self.headers_access(headers, key)
    value = headers[key]
    if value == headers
      return nil
    end
    value
  end


  def initialize(initial_detection, content)
    @mime_type = initial_detection[0]
    
    @character_set = initial_detection[1]
    
    validate_character_encoding(content)
  end

  def validate_character_encoding(content)
    # detection = CharlockHolmes::EncodingDetector.detect(content)
    unless(@mime_type)
      @mime_type = content_mime_detection(content)
    end
    
    detection = content.encoding.name
     if(detection != @character_set)
       # prefer the detected character set rather than the provided data
        @character_set = detection
     end
        
  end

  def convert_to_utf8(content)
    # if we can find a way to make charlock_holmes work on heroku,
    # then this line will work, and do what is required. Until this
    # point, we just return content
    #CharlockHolmes::Converter.convert(content, @character_set, 'UTF-8')
    
    content
  end


  def content_mime_detection(content)
    # this is kind of a bad
    # idea... BUT we do proper parsing later
    match = /<.*body.*>/.match(content)
    
    if match
      return "text/html"
    else
      return "application/octet-stream"
    end
  end
  
  
  
end

