require 'set'
#module Cobweb
  # This is not intended to be scalable, its only intention is to be solid and correct.
  class SimpleCrawl

    attr_reader :content
    attr_reader :options
    attr_reader :urls
    attr_accessor :robot
    
    def initialize(options={})
      @counter = 0
      @urls = Set.new
      @crawled = Set.new
      @options = setup_defaults(HashUtil.deep_symbolize_keys(options))
      if(@options[:obey_robots] == "true")
        puts "USING ROBOTS!"
        @robot = Robots.new(@options)
      end
    end

    
    def retrieve(url=nil,count=0)
      puts " retrieve: count: #{count}"
      url = @options[:url] unless url
      url = clean_url(url)
      allowed = true
      @urls << url # the mechanics of the set ensure no duplicates

      if (@robot)
        return false unless @robot.allowed?(url)
      end
      
      if @options[:use_sitemap] == "true"
        puts "USING SITEMAP"
        begin
          @urls = sitemap_retrieval(url)
          # If there is nothing in the urls, we need to crawl normally
          return true unless @urls.size == 0
        rescue CobwebSitemap::SitemapNotFoundError
          # crawl normally
        end
      end
      
      
      cobweb = Cobweb.new(@options)

      if within_crawl_limits?
        raw_content = cobweb.get(url) 
        
        content = CobwebModule::CrawlObject.new(raw_content, @options)

        # We cant continue if the various error exceptions are thrown
        return false if(raw_content[:mime_type] =~ /error.*/)
          
        process_links(content)
        @crawled << url
        url_arr = @urls.to_a
        
        if within_crawl_limits? && dig? 
          new_count = count+1
          uri = url_arr[new_count]
          if uri
            status = retrieve(uri, new_count) unless @crawled.include?(uri)
          end          
        end
        
        return true if content.permitted_type?
        
      end
      
      return false
    end
    

    private

    def sitemap_retrieval(url)
      sm_url = @options[:sitemap_url] unless @options[:sitemap_url].empty? 
      sm_url = url unless sm_url

      sm_url_provided = (@options[:sitemap_url].empty? ? false : true ) 
      parser = SitemapParser.new(sm_url, sm_url_provided)
      
      maps = parser.build unless @options[:crawl_limit]
      maps = parser.build(@options[:crawl_limit]) if @options[:crawl_limit]
      
      condensed = parser.condense
      puts "URLS FOUND: #{condensed.urls} "
      puts "MAPS #{maps}"
      
      @urls = Set.new(parser.raw_urls(condensed))
    end

    
    def setup_defaults(options)
      options[:crawl_limit_by_page] = false unless options.has_key? :crawl_limit_by_page
      options[:valid_mime_types] = ["*/*"] unless options.has_key? :valid_mime_types
      
      options
    end

    def clean_url(url)
      clean = url.strip
      if url[-1] == "/"
         clean = url[0..-2]
      end

      clean
    end
    

    def dig?
      if options[:depth]
        return true if @options[:depth] > 0
      else
        return true #if not specified we will dig into links
      end
      false
    end
    
    def process_links(content, &block)

      # set the base url if this is the first page
      #set_base_url @redis

      @cobweb_links = CobwebLinks.new(@options)

      # check command queue for info as to what the next step is
      
      if within_crawl_limits?
        begin
          internal_links = ContentLinkParser.new(@options[:url], content.body, @options).all_links(:valid_schemes => [:http, :https])
          #get rid of duplicate links in the same page.
          #internal_links.each {|l| puts "link found :#{l}" }
          
          internal_links.uniq!
          # select the link if its internal
          internal_links.select! { |link| @cobweb_links.internal?(link) }
          count = 0
          count = internal_links.inject {|memo, l| count += 1  }
          puts ("count found #{count}")
          
          # reject the link if we've already queued it
          internal_links.reject! { |link| @urls.include? link }
        
          internal_links.each do |link|

            yield link if block_given?
            clean_link = clean_url(link)
            @urls << clean_link if within_crawl_limits?
          end
        rescue NoMethodError => e
          puts "no body for this content"
        end
        
      end
      

    end


    def within_crawl_limits?
      if(@options[:crawl_limit]) 
        return @urls.size < @options[:crawl_limit]
      end
      true
    end
    
    
  end
  
#end
