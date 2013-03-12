require 'nokogiri'


module CobwebSitemap
  
  
  class Sitemap
    attr_accessor :urls
    attr_accessor :content

    def initialize(content)
      raise "subclass must override"
    end
    
  end
  
  
  class XmlSitemap < Sitemap
    def initialize(content)
      @urls = []
      @xml = Nokogiri::XML(content)
      @xml.remove_namespaces!
      parse(@xml)
      
    end

    def parse(xml)
      url_nodes = xml.xpath("/urlset/url")
      @urls = url_nodes.map { |unode| SitemapUrl.build_from_xml(unode) }
    end
    
    
  end

  class TextSitemap < Sitemap
    def initialize(content)
      
    end
    
  end
  

  class SitemapUrl
    attr_accessor :url
    attr_accessor :modified
    attr_accessor :change_frequency
    attr_accessor :priority

    def initialize(url)
      @url = url
    end

    def self.build_from_xml(node)
      n = SitemapUrl.new(content(node,"./loc"))
      n.modified         = content(node, "./lastmod")
      n.change_frequency = content(node,"./changefreq")
      n.priority         = content(node, "./priority")
      n
    end

    def self.content(node, xpath)
      node.xpath(xpath).text
    end
    
  end

  
  
end
