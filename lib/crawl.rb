module CobwebModule
  class Crawl
    
    def initialize(options={})
      @options = HashUtil.deep_symbolize_keys(options)
      
      setup_defaults
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{@options[:crawl_id]}", Redis.new(@options[:redis_options]))
      @stats = Stats.new(@options)
      @debug = @options[:debug]
      @first_to_finish = false
      
    end
    
    # Returns true if the url requested is already in the crawled queue
    def already_crawled?(link=@options[:url])
       @redis.sismember "crawled", link
    end
    
    def already_queued?(link)
      @redis.sismember "queued", link
    end
    
    # Returns true if the crawl count is within limits
    def within_crawl_limits?
      @options[:crawl_limit].nil? || crawl_counter < @options[:crawl_limit].to_i
    end

    # Returns true if the processed count is within limits
    def within_process_limits?
      @options[:crawl_limit].nil? || process_counter < @options[:crawl_limit].to_i
    end

    # Returns true if the queue count is calculated to be still within limits when complete
    def within_queue_limits?
      
      # if we are limiting by page we can't limit the queue size as we don't know the mime type until retrieved
      if @options[:crawl_limit_by_page]
        return true
        
      # if a crawl limit is set, limit queue size to crawled + queue
      elsif @options[:crawl_limit].to_i > 0
        (queue_counter + crawl_counter) < @options[:crawl_limit].to_i
      
      # no crawl limit set so always within queue limit
      else
        true
      end
    end
    
    def retrieve
      unless already_crawled?
        if within_crawl_limits?
          @stats.update_status("Retrieving #{@options[:url]}...")
          @content = Cobweb.new(@options).get(@options[:url], @options)
          if @options[:url] == @redis.get("original_base_url")
             @redis.set("crawled_base_url", @content[:base_url])
          end
          update_queues
      
          if content.permitted_type?
            ## update statistics
          
            @stats.update_statistics(@content)
            return true
          end
        else
          decrement_queue_counter
        end
      else
        decrement_queue_counter
      end
      false
    end
    
    def process_links &block
      
      # set the base url if this is the first page
      set_base_url @redis
      
      @cobweb_links = CobwebLinks.new(@options)
      if within_queue_limits?
        internal_links = ContentLinkParser.new(@options[:url], content.body, @options).all_links(:valid_schemes => [:http, :https])
        #get rid of duplicate links in the same page.
        internal_links.uniq!
        # select the link if its internal
        internal_links.select! { |link| @cobweb_links.internal?(link) }

        # reject the link if we've crawled it or queued it
        internal_links.reject! { |link| @redis.sismember("crawled", link) }
        internal_links.reject! { |link| @redis.sismember("queued", link) }

        internal_links.each do |link|
          if within_queue_limits? && !already_queued?(link) && !already_crawled?(link)
            if status != CobwebCrawlHelper::CANCELLED
              yield link if block_given?
              unless link.nil?
                @redis.sadd "queued", link
                increment_queue_counter
              end
            else
              puts "Cannot enqueue new content as crawl has been cancelled." if @options[:debug]
            end
          end
        end
      end
    end
    
    def content
      raise "Content is not available" if @content.nil?
      CobwebModule::CrawlObject.new(@content, @options) 
    end
    
    def update_queues
      @redis.multi do
        #@redis.incr "inprogress"
        # move the url from the queued list to the crawled list - for both the original url, and the content url (to handle redirects)
        @redis.srem "queued", @options[:url]
        @redis.sadd "crawled", @options[:url]
        if content.url != @options[:url]
          @redis.srem "queued", content.url
          @redis.sadd "crawled", content.url
        end
        # increment the counter if we are not limiting by page only || we are limiting count by page and it is a page
        if @options[:crawl_limit_by_page]
          ap "#{content.mime_type} - #{content.url}"
          if content.mime_type.match("text/html")
            increment_crawl_counter
          end
        else
          increment_crawl_counter
        end
        decrement_queue_counter
      end
    end
    
    def to_be_processed?
      !finished? || first_to_finish? || within_process_limits?
    end
    
    def process
      if @options[:crawl_limit_by_page]
        if content.mime_type.match("text/html")
          increment_process_counter
        end
      else
        increment_process_counter
      end
    end
    
    def finished?
      print_counters
      # if there's nothing left queued or the crawled limit has been reached
      if @options[:crawl_limit].nil? || @options[:crawl_limit] == 0
        if queue_counter.to_i == 0
          finished
          return true
        end
      elsif (queue_counter.to_i) == 0 || crawl_counter.to_i >= @options[:crawl_limit].to_i
        finished
        return true
      end
      false
    end
    
    def finished
      set_first_to_finish if !@redis.exists("first_to_finish")
      ap "CRAWL FINISHED  #{@options[:url]}, #{counters}, #{@redis.get("original_base_url")}, #{@redis.get("crawled_base_url")}" if @options[:debug]
      @stats.end_crawl(@options)
    end
    
    def set_first_to_finish
      @redis.watch("first_to_finish") do
        if !@redis.exists("first_to_finish")
          @redis.multi do
            puts "set first to finish"
            @first_to_finish = true
            @redis.set("first_to_finish", 1)
          end
        else
          @redis.unwatch
        end
      end
    end
    
    
    def first_to_finish? 
      @first_to_finish
    end
    
    def crawled_base_url
      @redis.get("crawled_base_url")
    end
    
    def statistics
      @stats.get_statistics
    end
    
    def redis
      @redis
    end
    
    private
    def setup_defaults
      @options[:redis_options] = {} unless @options.has_key? :redis_options
      @options[:crawl_limit_by_page] = false unless @options.has_key? :crawl_limit_by_page
      @options[:valid_mime_types] = ["*/*"] unless @options.has_key? :valid_mime_types
    end
    
    # Increments the queue counter and refreshes crawl counters
    def increment_queue_counter
      @redis.incr "queue-counter"
    end
    # Increments the crawl counter and refreshes crawl counters
    def increment_crawl_counter
      @redis.incr "crawl-counter"
    end
    # Increments the process counter
    def increment_process_counter
      @redis.incr "process-counter"
    end
    # Decrements the queue counter and refreshes crawl counters
    def decrement_queue_counter
      @redis.decr "queue-counter"
    end
    
    def crawl_counter
      @redis.get("crawl-counter").to_i
    end
    def queue_counter
      @redis.get("queue-counter").to_i
    end
    def process_counter
      @redis.get("process-counter").to_i
    end
    
    def status
      @stats.get_status
    end
    
    def print_counters
      puts counters
    end
    
    def counters
      "crawl_counter: #{crawl_counter} queue_counter: #{queue_counter} process_counter: #{process_counter} crawl_limit: #{@options[:crawl_limit]}"
    end
    
    # Sets the base url in redis.  If the first page is a redirect, it sets the base_url to the destination
    def set_base_url(redis)
      if redis.get("base_url").nil?
        unless !defined?(content.redirect_through) || content.redirect_through.empty? || !@options[:first_page_redirect_internal]
          uri = Addressable::URI.parse(content.redirect_through.last)
          redis.sadd("internal_urls", [uri.scheme, "://", uri.host, "/*"].join)
        end
        redis.set("base_url", content.url)
      end
    end


    
  end
end