class SampleServer

  # This is the root of our app
  @root = File.expand_path(File.dirname(__FILE__)) + "/sample_site"

  @redirect_counter = 0
  
  def self.app
    Proc.new { |env|
      # Extract the requested path from the request
      path = Rack::Utils.unescape(env['PATH_INFO'])
      index_file = @root + "#{path}/index.html"

      if File.exists?(index_file)
        # Return the index
        [200, {'Content-Type' => 'text/html'}, File.read(index_file)]
      elsif(path.include?("redirect-request"))
        
        if(@redirect_counter <= 8)
          @redirect_counter += 1
          [302, {'Content-Type' => 'text/html', 'Location'=> 'http://localhost:3532/redirect-request.html',
                 'Set-Cookie' => "TLDR-123555444"}, "" ]
        else
          [200, {'Content-Type' => 'text/html'}, File.read(@root + "/index.html")]
        end
        
      else
        # Pass the request to the directory app
        Rack::Directory.new(@root).call(env)
      end
    }
  end
end
