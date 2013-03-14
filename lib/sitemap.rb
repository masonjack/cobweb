require 'nokogiri'
require 'typhoeus'

module CobwebSitemap
  
  
  class Sitemap
    attr_accessor :urls
    attr_accessor :content

  end

  class SiteIndex
    attr_accessor :maps

    # really simple somewhat silly check for index content
    def self.index?(content)
      content =~ /<.*sitemapindex.*>/
    end

    def initialize(content, map_type=XmlSitemap, limit=0)
      # TODO: need to support other sitemap types, since this wont
      # do anything should we come across a text sitemap file
      doc = Nokogiri::XML(content)
      doc.remove_namespaces!
      index_doc = doc.xpath("/sitemapindex")
      if index_doc.length > 0
        locations = doc.xpath("/sitemapindex/sitemap/loc")
        @maps = locations.map do |location|
          content = Utils.retrieve(location.text)
          map_type.new(content.body, limit)
        end
      end
    end

  end
  
  
  class XmlSitemap < Sitemap
    def initialize(content, limit=0)
      @urls = []
      xml = Nokogiri::XML(content)
      xml.remove_namespaces!
      parse(xml, limit)
      
    end

    def parse(xml, limit)
      url_nodes = xml.xpath("/urlset/url")
      if limit > 0
        nodes = url_nodes.slice(0,limit)
      else
        nodes = url_nodes
      end
      
      
      @urls = nodes.map { |unode| SitemapUrl.build_from_xml(unode) }
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


  class Utils
    def self.retrieve(location)
      Typhoeus::Request.new(location).run
    end

  end
  
  
end
