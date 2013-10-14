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
      uri_path = LinksCobweb.get_host_path(url.to_s)
      @location = "#{uri_path}/sitemap.xml"
    end
    puts "attempting to retrieve :#{@location}"    
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
    #if it ends with html or htm, we do not support it - we only do xml atm
    raise CobwebSitemap::SitemapNotValid, "Sitemap not valid" if location.to_s.end_with?(".htm", ".html")

    response = CobwebSitemap::Utils.retrieve(location)
    raise CobwebSitemap::SitemapNotFoundError, "No Sitemap found" if response[:status_code] == 404

    # parse response.body strictly
    begin
      xml_doc = Nokogiri::XML(response[:body]){ |config| config.strict }
    rescue Nokogiri::XML::SyntaxError => e
      puts "SITEMAP INVALID: Caught exception: #{e}"
      raise CobwebSitemap::SitemapNotValid, "Sitemap not valid"
    end

    @type = sitemap_type(response)
    @content = response[:body]
    puts "SiteMap request result: #{@content}"
    #puts @content
  end
  
  def sitemap_type(response)
    type = response[:content_type]
    #puts "responseType:: #{type}"
    # Only supporting xml sitemaps at this point in time
    CobwebSitemap::XmlSitemap
    #return CobwebSitemap::TextSitemap
  end  
  
  
end
