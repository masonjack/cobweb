require "addressable/uri"
require "aws/s3"

# Simply outputs the content recieved to the console
class CobwebNullUrlProcessor
  def self.perform(content_options)
    puts content_options if content_options[:debug] 
  end
end

class S3FilePersistanceProcessor
  def self.perform(content_options)
    
  end
  
end

class LocalFilePersistanceProcessor
  def self.perform(content)
    root_dir = "#{Dir.home}/temp"
    content_to_save = content[:body]
    url = content[:url]
    filename = url[url.rindex("/"),url.length]
    
    uri = Addressable::URI.parse(url)
    time = Time.now
    
    base_path = "#{root_dir}/#{uri.host}/#{time.year}/#{time.month}/#{time.day}/#{content[:crawl_id]}"
    path = uri.path.sub(filename, "")
    
    FileUtils.mkdir_p("#{base_path}#{path}")
    File.open("#{base_path}/#{uri.path}", "w") {|f| f.puts content_to_save }
    
  end
  
end

