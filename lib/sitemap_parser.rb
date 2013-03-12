require 'typhoeus'
require 'nokogiri'


class SitemapParser

  attr_accessor :location
  attr_reader :sitemap
  
  def initialize(url, url_is_sitemap_location=false)
    if url_is_sitemap_location
      @location = url
    else
      uri = Addressable::URI.parse(url)
      @location = [uri.scheme, "://", uri.host, (uri.port ? ":#{uri.port}": "") , "/", "sitemap.xml"].join
    end
    puts "attempting to retrieve :#{@location}"
    get_base_content(@location)
  end

  def get_base_content(location)
    
    response = retrieve(location)
    raise "No Sitemap found" if response.code == 404
    
    @type = sitemap_type(response)
    @content = response.body
    puts @content
  end
  
  def sitemap_type(response)
    type = response.headers["content-type"]
    puts "responseType:: #{type}"
    return CobwebSitemap::XmlSitemap if type == "application/xml"
    return CobwebSitemap::TextSitemap
  end  

  def build
    output = nil
    if @type
      begin
        doc = Nokogiri::XML(@content)
        doc.remove_namespaces!
        index_doc = doc.xpath("/sitemapindex")
        if index_doc
          locations = doc.xpath("/sitemapindex/sitemap/loc").text
          output = locations.map do |location|
            content = retrieve(location)
            @type.new(content)
          end
        else
          # root sitemap.xml is the actual doc
          output = [@type.new(@content)]
        end
      end
    end

    output
  end

  private
  
  def retrieve(location)
    Typhoeus::Request.new(location).run
  end
  
  
end
