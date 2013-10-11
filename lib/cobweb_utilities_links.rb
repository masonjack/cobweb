require 'stringio'
require 'typhoeus'

module CobwebUtilitiesLinks

  VALID_RESPONSE_CODES = [*(100..102), *(200..208), 226, 250, *(300..308)]
  INVALID_RESPONSE_CODES = [0, 400, *(402..406), *(408..462), *(494..499), *(500..511), 550, 551, 598, 599]

  # returns the response for a given link & method
  # response is a hash
  def self.check_link(link, method)
    max_redirs = 10
    cookie_jar = "tmp"
    response = Typhoeus::Request.new(link.to_s,
                                     :method => method,
                                     :ssl_verifypeer =>false,
                                     :ssl_verifyhost => 0,
                                     #:sslversion => :sslv3,
                                     :followlocation => true,
                                     :timeout => 10,
                                     :verbose => false,
                                     :cookiefile => cookie_jar,
                                     :cookiejar => cookie_jar,
                                     :maxredirs => max_redirs,
                                     :headers => { 'Accept' => "*/*"}).run
    #Rails.logger.debug("link: #{link.to_s}, method: #{method}, response = #{response.inspect}")
    return response
  end

  # gets the last effective url (max of 10 redirects) if the url is redirecting to somewhere
  def self.get_effective_url(link)
    return check_link(link,"get").effective_url
  end

  def self.get_host_path(uri)
    output = ''
    path = ''

    link = uri.to_s.downcase.strip
    link.gsub!(' ', '%20')

    # pull out scheme
    scheme = link.match(/https?:\/\//)
    url = link.gsub(/https?:\/\//,'')
    output << scheme.to_s

    # find last instance of '/'
    slash = url.rindex('/')
    if slash
      host = url.slice(0, slash.to_i)
      output << host.to_s

      path = url.slice(slash.to_i, url.length)
      # ignore the path if it is only a "/"
      path = '' if path.strip == "/"
      dot = path.rindex('.')
      output << path.to_s unless dot
    else
      output << url.to_s << path.to_s
    end

    return output.to_s
  end


end


