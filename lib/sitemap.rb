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

        url_count = 0
        # more functional way to do this would be nicer
        @maps = locations.map do |location|
          if limit == 0
            build_map(location, map_type)
          else
            if url_count < limit
              m = build_map(location, map_type)
              
              m.urls = m.urls.slice(0,limit)
              size = m.urls.size
              
              if(size + url_count > limit)
                # slice up to the limit
                slice_size = limit - url_count
                m.urls = m.urls.slice(0, slice_size)
              end
              url_count += size
              
              m
            end            
          end
          
        end
        @maps.reject!{|m| m.nil?}
      end
    end

    private
    def build_map(location, map_type)
      content = Utils.retrieve(location.text)
      m = map_type.new(content.body)
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
      Typhoeus.get(location, :followlocation => true)
    end


  end

  class SitemapNotFoundError < StandardError
  end
  
  
end
