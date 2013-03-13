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
    #puts "attempting to retrieve :#{@location}"
    get_base_content(@location)
  end

  def get_base_content(location)
    
    response = CobwebSitemap::Utils.retrieve(location)
    raise "No Sitemap found" if response.code == 404
    
    @type = sitemap_type(response)
    @content = response.body
    #puts @content
  end
  
  def sitemap_type(response)
    type = response.headers["content-type"]
    #puts "responseType:: #{type}"
    return CobwebSitemap::XmlSitemap if type == "application/xml"
    return CobwebSitemap::TextSitemap
  end  

  def build
    output = nil
    if @type
      begin
        if CobwebSitemap::SiteIndex.index?(@content)
          index = CobwebSitemap::SiteIndex.new(@content, @type)
          output = index.maps
        else
          output = []
          # root sitemap.xml is the actual doc
          out = @type.new(@content)
          
          output << out
        end
      end
    end
    @maps = output
    output
  end


  # Returns a single sitemap with all urls from all retrieved sitemaps
  def condense
    container = CobwebSitemap::Sitemap.new
    container.urls = @maps.map { |map| map.urls.map{|url| url} }
    container
  end
  

  
  
end
