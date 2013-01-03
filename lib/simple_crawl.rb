
#module Cobweb
  # This is not intended to be scalable, its only intention is to be solid and correct.
  class SimpleCrawl

    attr_reader :content
    attr_reader :options
    attr_reader :urls
    
    def initialize(options={})
      @counter = 0
      @urls = []
      @crawled = []
      @options = setup_defaults(HashUtil.deep_symbolize_keys(options))      
    end

    def retrieve(url=nil,count=0)
      puts " retrieve: count: #{count}"
      
      url = @options[:url] unless url
      @urls << url unless @urls.include? url
      
      cobweb = Cobweb.new(@options)

      if within_crawl_limits?
        raw_content = cobweb.get(url)
        
        content = CobwebModule::CrawlObject.new(raw_content, @options)

        # We cant continue if the various error exceptions are thrown
        return false if(raw_content[:mime_type] =~ /error/)
          
        process_links(content)
        @crawled << url
        
        if within_crawl_limits? && dig? 
          new_count = count+1
          uri = @urls[new_count]
          if uri
            status = retrieve(uri, new_count) unless @crawled.include?(uri)
          end          
        end
        
        return true if content.permitted_type?
        
      end
      
      return false
    end
    

    private

    def setup_defaults(options)
      options[:crawl_limit_by_page] = false unless options.has_key? :crawl_limit_by_page
      options[:valid_mime_types] = ["*/*"] unless options.has_key? :valid_mime_types
      
      options
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
            @urls << link if within_crawl_limits? 
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
