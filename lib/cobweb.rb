require 'rubygems'
require 'uri'
require 'resque'
require "addressable/uri"
require 'digest/sha1'
require 'base64'
require 'resque/batched_job'

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
    default_processing_queue_to               "UrlProcessingJob"
    default_crawl_finished_queue_to           "CobwebFinishedJob"
    default_url_processor_to                  "CobwebNullUrlProcessor"
    default_additional_url_processors_to      []
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
    default_cache_manager_to                   "DummyCache"
    default_crawl_limit_to                     100
    default_use_sitemap_to                     false
    default_use_js_to                          false
    puts @options
    @cache_manager = instanciate(@options[:cache_manager], @options)
    
  end
  
  # This method starts the resque based crawl and enqueues the base_url
  def start(base_url)
    raise ":base_url is required" unless base_url
    request = {
      :crawl_id => Digest::SHA1.hexdigest("#{Time.now.to_i}.#{Time.now.usec}"),
      :url => base_url 
    }  

    @options = CobwebLinks.default_internal_urls(@options)
    request.merge!(@options)
    
    Resque.enqueue(SpiderJob, request)
    request
  end
  
  # Returns array of cookies from content
  def get_cookies(response)
    all_cookies = response.headers["Set-Cookie"] || response.headers["set-cookie"]
    unless all_cookies.nil?
      cookies_array = Array.new
      all_cookies.each { |cookie|
        cookies_array.push(cookie.split('; ')[0])
      }
      cookies = cookies_array.join('; ')
    end
  end

  # Performs a HTTP GET request to the specified url applying the options supplied in addition to the options being used for the current cobweb instance
  def get(url, options = {})
    request(url, :get, @cache_manager, options)
  end

  # Performs a HTTP GET request to the specified url applying the options supplied in addition to the options being used for the current cobweb instance
  def head(url, options = {})
    request(url, :head, @cache_manager, options)
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

  def instanciate(object_name, args)
    klass = Object::const_get(object_name)
    klass.new(args)
  end

  
  
end
