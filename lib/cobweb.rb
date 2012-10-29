require 'rubygems'
require 'uri'
require 'resque'
require "addressable/uri"
require 'digest/sha1'
require 'base64'

Dir[File.dirname(__FILE__) + '/**/*.rb'].each do |file|
  require file
end

# Cobweb class is used to perform get and head requests.  You can use this on its own if you wish without the crawler
class Cobweb

  include CobwebRequest
  
  # retrieves current version
  def self.version
    CobwebVersion.version
  end
  
  # used for setting default options
  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^default_(.*)_to$/
      tag_name = method_sym.to_s.split("_")[1..-2].join("_").to_sym
      @options[tag_name] = arguments[0] unless @options.has_key?(tag_name)
    else
      super
    end
  end
  
  # See readme for more information on options available
  def initialize(options = {})
    @options = options
    default_use_encoding_safe_process_job_to  false
    default_follow_redirects_to               true
    default_redirect_limit_to                 10
    default_processing_queue_to               "CobwebProcessJob"
    default_crawl_finished_queue_to           "CobwebFinishedJob"
    default_quiet_to                          true
    default_debug_to                          false
    default_cache_to                          300
    default_timeout_to                        10
    default_redis_options_to                  Hash.new
    default_internal_urls_to                  []
    default_first_page_redirect_internal_to   true
    default_text_mime_types_to                ["text/*", "application/xhtml+xml"]
    default_obey_robots_to                    false
    default_user_agent_to                     "cobweb/#{Cobweb.version} (ruby/#{RUBY_VERSION} nokogiri/#{Nokogiri::VERSION})"
    default_valid_mime_types_to                ["*/*"]
    
  end
  
  # This method starts the resque based crawl and enqueues the base_url
  def start(base_url)
    raise ":base_url is required" unless base_url
    request = {
      :crawl_id => Digest::SHA1.hexdigest("#{Time.now.to_i}.#{Time.now.usec}"),
      :url => base_url 
    }  
    
    if @options[:internal_urls].nil? || @options[:internal_urls].empty?
      uri = Addressable::URI.parse(base_url)
      @options[:internal_urls] = []
      @options[:internal_urls] << [uri.scheme, "://", uri.host, "/*"].join
      @options[:internal_urls] << [uri.scheme, "://", uri.host, ":", uri.inferred_port, "/*"].join
    end
    
    request.merge!(@options)
    @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{request[:crawl_id]}", :redis => Redis.new(request[:redis_options]))
    @redis.set("original_base_url", base_url)
    @redis.hset "statistics", "queued_at", DateTime.now
    @redis.set("crawl-counter", 0)
    @redis.set("queue-counter", 1)
    
    @stats = Stats.new(request)
    @stats.start_crawl(request)
    
    # add internal_urls into redis
    @options[:internal_urls].map{|url| @redis.sadd("internal_urls", url)}
    Resque.enqueue(CrawlJob, request)
    request
  end
  
  # Returns array of cookies from content
  def get_cookies(response)
    all_cookies = response.get_fields('set-cookie')
    unless all_cookies.nil?
      cookies_array = Array.new
      all_cookies.each { |cookie|
        cookies_array.push(cookie.split('; ')[0])
      }
      cookies = cookies_array.join('; ')
    end
  end

  # Performs a HTTP GET request to the specified url applying the options supplied
  def get(url, options = @options)
    request(url, :get, options)
  end

  # Performs a HTTP HEAD request to the specified url applying the options supplied
  def head(url, options = @options)
    request(url, :head, options)
  end


  # escapes characters with meaning in regular expressions and adds wildcard expression
  def self.escape_pattern_for_regex(pattern)
    pattern = pattern.gsub(".", "\\.")
    pattern = pattern.gsub("?", "\\?")
    pattern = pattern.gsub("+", "\\+")
    pattern = pattern.gsub("*", ".*?")
    pattern
  end
  
  private
  # checks if the mime_type is textual
  def text_content?(content_type)
    @options[:text_mime_types].each do |mime_type|
      return true if content_type.match(Cobweb.escape_pattern_for_regex(mime_type))
    end
    false
  end
  
end
