
class UrlProcessingJob

  @queue = :cobweb_content_processing

  def self.perform(content_options)

    # fetch the content
    processor = Cobweb.new(content_options)
    url = content_options[:retrieve_url] || content_options[:url]
    
    content = processor.get( url, content_options)
    content_to_send = content_options.merge(content)

    clazz = const_get(content_options[:url_processor])
    clazz.perform(content_to_send)
    
  end
  
end
