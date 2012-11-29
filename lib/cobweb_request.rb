require 'typhoeus'


module CobwebRequest
  
  def request(url, type, cache_manager, options)

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
    
    content = {:base_url => url}
    http_opts = {}
    
    # check if it has already been cached
    if cache_manager.in_cache?(unique_id)
      puts "Cache hit for #{url}" unless options[:quiet]
      content = cache_manager.get(unique_id)
    
    else
      # retrieve data
      if uri.scheme == "https"
        http_opts[:ssl_verifypeer] = false
      end

      http_opts[:timeout] = options[:timeout].to_i
      http_opts[:connecttimeout] = options[:timeout].to_i
      
      request_time = Time.now.to_f
      
      begin
        print "Retrieving #{url }... " unless options[:quiet]
        
        
        #if options[:cookies]
        #  request_options[ 'Cookie']= options[:cookies]
        #end

        if type == :get
          response = Typhoeus::Request.get(url, http_opts)
        elsif type == :head
          response = Typhoeus::Request.head(url, http_opts)
        end
        
        if options[:follow_redirects] and response.code.to_i >= 300 and response.code.to_i < 400
          puts "redirected... " unless options[:quiet]
          
          # get location to redirect to
          uri = UriHelper.join_no_fragment(uri, response.headers["location"])
          
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
          
          puts "Retrieved." unless options[:quiet]

          # create the content container
          content[:url] = uri.to_s
          content[:status_code] = response.code.to_i
          content[:mime_type] = ""
          unless response.headers["content-type"].nil?
            content[:mime_type] = response.headers["content-type"].split(";")[0].strip
            ct = response.headers["content-type"]
            
            if ct.include?(";")
              charset = ct[ct.index(";")+2..-1] if !ct.nil? and ct.include?(";")
              charset = charset[charset.index("=")+1..-1] if charset and charset.include?("=")
              content[:character_set] = charset
            end

            content.merge! body_processing(response, content, options) if type == :get
          end

        end
        
        # add content to cache if required
        if options[:cache]
          cache_manager.set(unique_id, content)
        else
          puts "Not storing in cache as cache disabled" if options[:debug]
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
      ensure
        cache_manager.close_connection
      end
    end
    content  
    
  end

  def get(url, options = nil)
  end


  def head(url, options = nil)
  end

  def head_processing(content, options)
    p
  end

  def body_processing(response, existing_content, options=nil)

    puts "BODY PROCESSING!" if options[:debug]
    
    content = {}
    content[:length] = response.headers["Content-Length"]
    content[:text_content] = text_content?(existing_content[:mime_type], options)
    
    if text_content?(existing_content[:mime_type], options)
      if response.headers["Content-Encoding"]=="gzip"
        content[:body] = Zlib::GzipReader.new(StringIO.new(response.body)).read
      else
        content[:body] = response.body
      end
    else
      content[:body] = Base64.encode64(response.body)
    end

    content[:location] = response.headers["location"]
         
    content[:headers] = HashUtil.deep_symbolize_keys(response.headers)
    # parse data for links
    link_parser = ContentLinkParser.new(content[:url], content[:body])
    content[:links] = link_parser.link_data
    
    content
  end


  def text_content?(content_type, options)
    options[:text_mime_types].each do |mime_type|
      return true if content_type.match(Cobweb.escape_pattern_for_regex(mime_type))
    end
    false
  end
  
end
