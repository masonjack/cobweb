require File.join(File.dirname(__FILE__), 'links_cobweb')

# CobwebLinks processes links to determine whether they are internal or external links
class CobwebLinks
  def self.default_internal_urls(options)
    if options[:internal_urls].nil? || options[:internal_urls].empty?
      uri_path = LinksCobweb.get_host_path(options[:base_url].to_s)
      options[:internal_urls] = []
      options[:internal_urls] = ["#{uri_path}/*"] unless uri_path.empty?
    end
    options
  end

  # Initalise's internal and external patterns and sets up regular expressions
  def initialize(options={})
    @options = self.class.default_internal_urls(options)
    raise InternalUrlsMissingError, ":internal_urls is required" unless @options.has_key? :internal_urls
    raise InvalidUrlsError, ":internal_urls must be an array" unless @options[:internal_urls].kind_of? Array
    raise InvalidUrlsError, ":external_urls must be an array" unless !@options.has_key?(:external_urls) || @options[:external_urls].kind_of?(Array)
    @options[:external_urls] = [] unless @options.has_key? :external_urls
    @options[:debug] = false unless @options.has_key? :debug

    @internal_patterns = @options[:internal_urls].map{|pattern| Regexp.new("^#{Cobweb.escape_pattern_for_regex(pattern)}")}
    @internal_patterns << Regexp.new("^#{Cobweb.escape_pattern_for_regex(@options[:url])}") if @options[:url]
    @external_patterns = @options[:external_urls].map{|pattern| Regexp.new("^#{Cobweb.escape_pattern_for_regex(pattern)}")}

  end

  def allowed?(link)
    if @options[:obey_robots]
      robot = Robots.new(:url => link, :user_agent => @options[:user_agent])
      return robot.allowed?(link)
    else
      return true
    end
  end

  # Returns true if the link is matched to an internal_url and not matched to an external_url
  def internal?(uri)
    link = uri.to_s.downcase.strip
    matches_internal = !@internal_patterns.select{|pattern| link.match(pattern)}.empty?
    matches_external = !@external_patterns.select{|pattern| link.match(pattern)}.empty?
    puts "LINK=> #{link.to_s} MATCH_INT=>#{matches_internal} MATCH_EXT=>#{matches_external}"
    return (matches_internal && !matches_external)
  end

  # Returns true if the link is matched to an external_url or not matched to an internal_url
  def external?(uri)
    link = uri.to_s.downcase.strip
    matches_internal = !@internal_patterns.select{|pattern| link.match(pattern)}.empty?
    matches_external = !@external_patterns.select{|pattern| link.match(pattern)}.empty?
    puts "LINK=> #{link.to_s} MATCH_INT=>#{matches_internal} MATCH_EXT=>#{matches_external}"
    return (matches_external || !matches_internal)
  end

end

# Exception raised for :internal_urls missing from CobwebLinks
class InternalUrlsMissingError < Exception
end
# Exception raised for :internal_urls being invalid from CobwebLinks
class InvalidUrlsError < Exception
end

