
class UrlProcessingJob

  @queue = :cobweb_content_processing

  def self.perform(content_options)

    # fetch the content
    options = HashUtil.deep_symbolize_keys(content_options)
    processor = Cobweb.new(content_options)
    
    url = options[:retrieve_url]
    puts "url to be processed is #{url}"
    
    content = processor.get( url, options)
    content_to_send = content_options.merge(content)

    clazz = const_get(options[:url_processor])
    if(clazz.respond_to? :perform)
      clazz.perform(content_to_send)
    else
      raise "Supplied url_processor class does not respond to perform method"
    end
    
    
  end
  
end
