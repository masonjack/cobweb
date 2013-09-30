require 'stringio'

module CobwebCommon

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


