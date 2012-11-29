# Simply outputs the content recieved to the console
class CobwebNullUrlProcessor
  def self.perform(content_options)
    puts content_options if content_options[:debug] 
  end
end

  
