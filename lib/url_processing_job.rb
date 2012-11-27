
class UrlProcessingJob

  @queue = :cobweb_content_processing

  def self.perform(content_options)

    # fetch the content
    processor = Cobweb.new(content_options)
    url = content_options[:retrieve_url] || content_options[:url]
    
    content = processor.get( url, content_options)
    content_to_send = content_options.merge(content)

    clazz = const_get(content_options[:url_processor])
    if(clazz.respond_to? :perform)
      clazz.perform(content_to_send)
    else
      raise "Supplied url_processor class does not respond to perform method"
    end
    
    
  end
  
end
