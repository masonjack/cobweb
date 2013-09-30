require 'typhoeus'

module CobwebRequest

  def request(url, type, cache_manager, options)
    options = options.merge(@options)
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

    content = {:url => url}
    http_opts = {}

    # check if it has already been cached
    if cache_manager.in_cache?(unique_id)
      puts "Cache hit for #{url}" unless options[:quiet]
      content = cache_manager.get(unique_id)

    else
      # retrieve data
      if uri.scheme == "https"
        http_opts[:ssl_verifypeer] = false
        http_opts[:ssl_verifyhost] = 0
        http_opts[:sslversion] = :sslv3
      end

      http_opts[:timeout] = options[:timeout].to_i
      http_opts[:connecttimeout] = options[:timeout].to_i
      http_opts[:followlocation] = true if options[:follow_redirects]
      http_opts[:maxredirs] = redirect_limit
      http_opts[:cookiefile] = "tmp"
      http_opts[:cookiejar] = "tmp"
      http_opts[:verbose] = true

      request_time = Time.now.to_f

      begin
        puts "Retrieving #{url }... " unless options[:quiet]
        puts("options: #{http_opts}") if options[:debug]

        #if options[:cookies]
        #  request_options[ 'Cookie']= options[:cookies]
        #end

        if type == :get
          response = Typhoeus::Request.new(url, http_opts).run
          puts "get done" if options[:debug]
        elsif type == :head
          response = Typhoeus::Request.head(url, http_opts)
          puts "head done" if options[:debug]
        end

        if response.options[:return_code] == :couldnt_resolve_host
          raise SocketError, "Could not resolve hostname", caller
        end

        # if options[:follow_redirects] and response.code.to_i >= 300 and response.code.to_i < 400
        #   puts "redirected... " unless options[:quiet]

        #   # get location to redirect to
        #   puts "response - headers #{response.headers}"
        #   location = response.headers["location"] || response.headers["Location"]
        #   puts "redirecting to : #{location}, limit == #{redirect_limit}"
        #   uri = UriHelper.join_no_fragment(uri, location)

        #   # decrement redirect limit
        #   redirect_limit = redirect_limit - 1

        #   raise RedirectError, "Redirect Limit reached" if redirect_limit == 0
        #   cookies = get_cookies(response)

        #   # get the content from redirect location
        #   content = request(uri,type, cache_manager, options.merge(:redirect_limit => redirect_limit, :cookies => cookies))
        #   content[:url] = uri.to_s
        #   content[:redirect_through] = [] if content[:redirect_through].nil?
        #   content[:redirect_through].insert(0, url)

        #   content[:response_time] = Time.now.to_f - request_time
        # else
        content[:response_time] = Time.now.to_f - request_time
        content[:redirect_through] = response.redirections if response.redirect_count > 0

        puts "Retrieved." if options[:debug]

        # create the content container
        content[:url] = uri.to_s
        content[:status_code] = response.code.to_i
        content[:mime_type] = ""
        
        
          ctype = ContentProcessor.determine_content_type(response.body, response.headers)
          content[:character_set] = ctype.character_set
          content[:content_type] = ctype.content_type
          content[:mime_type] = ctype.mime_type
          
          
          if type == :get
            content.merge! body_processing(response, content, options)
            content[:body] = ctype.convert_to_utf8(response.body)
          end
        
        
        #end

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
    content[:length] = headers_access(response.headers, "content-length")
    content[:text_content] = text_content?(existing_content[:mime_type], options)
    content[:body] = ""
    response_body = ""
    if text_content?(existing_content[:mime_type], options)
      if (headers_access(response.headers,"content-encoding")=="gzip")
        response_body = Zlib::GzipReader.new(StringIO.new(response.body)).read
      else
        response_body = response.body
      end
    else
      response_body = Base64.encode64(response.body)
    end

    content[:location] = headers_access(response.headers, "location")

    raw_hash_headers = {}
    raw_hash_headers.replace(response.headers)
    content[:headers] = HashUtil.deep_symbolize_keys(raw_hash_headers)

    # parse data for links
    link_parser = ContentLinkParser.new(content[:url], response_body)
    content[:links] = link_parser.link_data

    content
  end

  # work around bug in typhoeus until fix is finalized
  # https://github.com/typhoeus/typhoeus/issues/227
  def headers_access(headers, key)
    value = headers[key]
    if value == headers
      return nil
    end
    value
  end


  def text_content?(content_type, options)
    puts "about to check for text_content"
    if(options[:text_mime_types])
      options[:text_mime_types].each do |mime_type|
        puts "checking text content"
        return true if content_type.match(Cobweb.escape_pattern_for_regex(mime_type))
      end
      false
    end
  end

end
