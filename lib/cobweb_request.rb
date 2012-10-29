
module CobwebRequest
  
  def request(url, type, options)

    raise "url cannot be nil" if url.nil?
    uri = Addressable::URI.parse(url)
    uri.normalize!
    uri.fragment=nil
    url = uri.to_s
    
    # get the unique id for this request
    unique_id = Digest::SHA1.hexdigest(url.to_s)
    unique_id = "head-#{unique_id}" if type == :head
    
    
    if options.has_key?(:redirect_limit) and !options[:redirect_limit].nil?
      redirect_limit = options[:redirect_limit].to_i
    else
      redirect_limit = 10
    end
    
    # connect to redis
    if options.has_key? :crawl_id
      redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{options[:crawl_id]}", :redis => Redis.new(@options[:redis_options]))
    else
      redis = Redis::Namespace.new("cobweb-#{Cobweb.version}", :redis => Redis.new(@options[:redis_options]))
    end

    content = {:base_url => url}
    
    # check if it has already been cached
    if redis.get(unique_id) and @options[:cache]
      puts "Cache hit for #{url}" unless @options[:quiet]
      content = HashUtil.deep_symbolize_keys(Marshal.load(redis.get(unique_id)))
    else
      # retrieve data
      unless @http && @http.address == uri.host && @http.port == uri.inferred_port
        puts "Creating connection to #{uri.host}..." if @options[:quiet]
        @http = Net::HTTP.new(uri.host, uri.inferred_port)
      end
      if uri.scheme == "https"
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      
      request_time = Time.now.to_f
      @http.read_timeout = @options[:timeout].to_i
      @http.open_timeout = @options[:timeout].to_i
      begin
        print "Retrieving #{url }... " unless @options[:quiet]
        request_options={}
        if options[:cookies]
          request_options[ 'Cookie']= options[:cookies]
        end
        
        requester = Net::HTTP::Get if type == :get
        requester = Net::HTTP::Head if type == :head
        request = requester.new uri.request_uri, request_options
        
        response = @http.request request
        
        if @options[:follow_redirects] and response.code.to_i >= 300 and response.code.to_i < 400
          puts "redirected... " unless @options[:quiet]
          
          # get location to redirect to
          uri = UriHelper.join_no_fragment(uri, response['location'])
          
          # decrement redirect limit
          redirect_limit = redirect_limit - 1

          raise RedirectError, "Redirect Limit reached" if redirect_limit == 0
          cookies = get_cookies(response)

          # get the content from redirect location
          content = request(uri,type, options.merge(:redirect_limit => redirect_limit, :cookies => cookies))
          content[:url] = uri.to_s
          content[:redirect_through] = [] if content[:redirect_through].nil?
          content[:redirect_through].insert(0, url)
          
          content[:response_time] = Time.now.to_f - request_time
        else
          content[:response_time] = Time.now.to_f - request_time
          
          puts "Retrieved." unless @options[:quiet]

          # create the content container
          content[:url] = uri.to_s
          content[:status_code] = response.code.to_i
          content[:mime_type] = ""
          unless response.content_type.nil?
            content[:mime_type] = response.content_type.split(";")[0].strip 
            if response["Content-Type"].include?(";")
              charset = response["Content-Type"][response["Content-Type"].index(";")+2..-1] if !response["Content-Type"].nil? and response["Content-Type"].include?(";")
              charset = charset[charset.index("=")+1..-1] if charset and charset.include?("=")
              content[:character_set] = charset
            end

            content.merge! body_processing(response, content) if type == :get
          end

        end
        # add content to cache if required
        if @options[:cache]
          redis.set(unique_id, Marshal.dump(content))
          redis.expire unique_id, @options[:cache].to_i
        else
          puts "Not storing in cache as cache disabled" if @options[:debug]
        end
        
      rescue RedirectError => e
        puts "ERROR RedirectError: #{e.message}"
        
        ## generate a blank content
        content = {}
        content[:url] = uri.to_s
        content[:response_time] = Time.now.to_f - request_time
        content[:status_code] = 0
        content[:length] = 0
        content[:body] = ""
        content[:error] = e.message
        content[:mime_type] = "error/dnslookup"
        content[:headers] = {}
        content[:links] = {}
        
      rescue SocketError => e
        puts "ERROR SocketError: #{e.message}"
        
        ## generate a blank content
        content = {}
        content[:url] = uri.to_s
        content[:response_time] = Time.now.to_f - request_time
        content[:status_code] = 0
        content[:length] = 0
        content[:body] = ""
        content[:error] = e.message
        content[:mime_type] = "error/dnslookup"
        content[:headers] = {}
        content[:links] = {}
        
      rescue Timeout::Error => e
        puts "ERROR Timeout::Error: #{e.message}"
        
        ## generate a blank content
        content = {}
        content[:url] = uri.to_s
        content[:response_time] = Time.now.to_f - request_time
        content[:status_code] = 0
        content[:length] = 0
        content[:body] = ""
        content[:error] = e.message
        content[:mime_type] = "error/serverdown"
        content[:headers] = {}
        content[:links] = {}
      end
    end
    content  
    
  end

  def get(url, options = @options)
  end


  def head(url, options = @options)
  end

  def head_processing(content, options)
    p
  end

  def body_processing(response, existing_content, options=nil)
    content = {}
    content[:length] = response.content_length
    content[:text_content] = text_content?(existing_content[:mime_type])
    if text_content?(existing_content[:mime_type])
      if response["Content-Encoding"]=="gzip"
        content[:body] = Zlib::GzipReader.new(StringIO.new(response.body)).read
      else
        content[:body] = response.body
      end
    else
      content[:body] = Base64.encode64(response.body)
    end

    content[:location] = response["location"]
    content[:headers] = HashUtil.deep_symbolize_keys(response.to_hash)
    # parse data for links
    link_parser = ContentLinkParser.new(content[:url], content[:body])
    content[:links] = link_parser.link_data
    
    content
  end

end
