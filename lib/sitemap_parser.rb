require 'typhoeus'
require 'nokogiri'


class SitemapParser

  attr_accessor :location
  attr_reader :sitemap
  
  def initialize(url, url_is_sitemap_location=false)
    if url_is_sitemap_location
      @location = url
    else
      # we are guessing the sitemap location here
      uri = Addressable::URI.parse(url)
      @location = [uri.scheme, "://", uri.host, (uri.port ? ":#{uri.port}": "") , "/", "sitemap.xml"].join
    end
    #puts "attempting to retrieve :#{@location}"
    get_base_content(@location)
  end

  

  # Builds the url list from the sitemaps to the limit of the urls
  # specified. If the limit is 0 or no limit specified, then no limiting is applied.
  def build(limit=0)
    output = nil
    if @type
      begin
        if CobwebSitemap::SiteIndex.index?(@content)
          index = CobwebSitemap::SiteIndex.new(@content, @type, limit)
          output = index.maps
        else
          output = []
          # root sitemap.xml is the actual doc
          out = @type.new(@content, limit)
          
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
    container.urls = @maps.map { |sitemap| sitemap.urls.map{|url| url}}.flatten
    #container.urls.flatten!
    puts "URLS: #{container.urls}"
    container
  end
  
  # gets the raw urls strings from the sitemap supplied
  def raw_urls(sitemap)
    sitemap.urls.map { |u| u.url }
  end
  
  private
  
  def get_base_content(location)
    
    response = CobwebSitemap::Utils.retrieve(location)
    raise "No Sitemap found" if response.code == 404
    
    @type = sitemap_type(response)
    @content = response.body
    puts "SiteMap request result: #{@content}" 
    #puts @content
  end
  
  def sitemap_type(response)
    type = response.headers["content-type"]
    #puts "responseType:: #{type}"
    # Only supporting xml sitemaps at this point in time
    CobwebSitemap::XmlSitemap
    #return CobwebSitemap::TextSitemap
  end  
  
  
end
