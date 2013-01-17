

  RSpec.configure do |config|
    
    config.before(:each) {
      
      #redis_mock = double("redis")
      #redis_mock.stub(:new).and_return(@redis_mock_object)
      
      #redis_mock.flushdb
      
      @default_headers = {"Cache-Control" => "private, max-age=0",
        "Date" => "Wed, 10 Nov 2010 09:06:17 GMT",
        "Expires" => "-1",
        "content-type" => "text/html; charset=UTF-8",
        "Content-Encoding" => "",
        "Transfer-Encoding" => "chunked",
        "Server" => "gws",
        "X-XSS-Protection" => "1; mode=block"}

      @symbolized_default_headers = {:"Cache-Control" => "private, max-age=0",
        :"Date" => "Wed, 10 Nov 2010 09:06:17 GMT",
        :"Expires" => "-1",
        :"content-type" => "text/html; charset=UTF-8",
        :"Content-Encoding" => "",
        :"Transfer-Encoding" => "chunked",
        :"Server" => "gws",
        :"X-XSS-Protection" => "1; mode=block"}
      @default_options = {:timeout=>10, :connecttimeout=>10}
      
      @mock_http_client = mock(Typhoeus)
      @mock_http_request = mock(Typhoeus::Request)
      @mock_http_robot_request = mock(Typhoeus::Request)
      
      
      @mock_http_response = mock(Typhoeus::Response)
      @mock_http_robot_response = mock(Typhoeus::Response)

      @mock_http_redirect_response = mock(Typhoeus::Response)
      @mock_http_redirect_response2 = mock(Typhoeus::Response)

      @mock_response_headers = mock(Typhoeus::Response::Header)
      
      Net::HTTP.stub!(:new).and_return(@mock_http_client)
      Typhoeus::Request.stub!(:get).with("http://www.baseurl.com/", @default_options).and_return(@mock_http_response)    
      Typhoeus::Request.stub!(:get).with("/robots.txt", @default_options).and_return(@mock_http_robot_request)

      Typhoeus::Request.stub!(:get).with("/redirect.html", @default_options).and_return(@mock_http_redirect_request)
      Typhoeus::Request.stub!(:get).with("/redirect2.html", @default_options).and_return(@mock_http_redirect_request2)

      
      Typhoeus::Request.stub!(:head).and_return(@mock_http_request)
      @mock_http_response.stub!(:code).and_return(200)
      @mock_http_response.stub!(:headers).and_return(@default_headers)

      @mock_http_client.stub!(:request).with(@mock_http_request).and_return(@mock_http_response)
      @mock_http_client.stub!(:request).with(@mock_http_robot_request).and_return(@mock_http_robot_response)
      @mock_http_client.stub!(:request).with(@mock_http_redirect_request).and_return(@mock_http_redirect_response)      
      @mock_http_client.stub!(:request).with(@mock_http_redirect_request2).and_return(@mock_http_redirect_response2)
      @mock_http_client.stub!(:read_timeout=).and_return(nil)      
      @mock_http_client.stub!(:open_timeout=).and_return(nil)      
      @mock_http_client.stub!(:start).and_return(@mock_http_response)
      @mock_http_client.stub!(:address).and_return("www.baseurl.com")
      @mock_http_client.stub!(:port).and_return("80 ")
      
      @mock_http_robot_response.stub!(:code).and_return(200)
      @mock_http_robot_response.stub!(:body).and_return(File.open(File.dirname(__FILE__) + '/../spec/samples/robots.txt', "r").read)
      @mock_http_robot_response.stub!(:content_type).and_return("text/plain")
      @mock_http_robot_response.stub!(:[]).with("Content-Type").and_return(@default_headers["Content-Type"])
      @mock_http_robot_response.stub!(:[]).with("location").and_return(@default_headers["location"])
      @mock_http_robot_response.stub!(:[]).with("Content-Encoding").and_return(@default_headers["Content-Encoding"])
      @mock_http_robot_response.stub!(:content_length).and_return(1024)
      @mock_http_robot_response.stub!(:get_fields).with('set-cookie').and_return(["session=al98axx; expires=Fri, 31-Dec-1999 23:58:23", "query=rubyscript; expires=Fri, 31-Dec-1999 23:58:23"])
      @mock_http_robot_response.stub!(:to_hash).and_return(@default_headers)
      
      @mock_http_response.stub!(:code).and_return(200)
      @mock_http_response.stub!(:content_type).and_return("text/html")
      @mock_http_response.stub!(:[]).with("Content-Type").and_return(@default_headers["Content-Type"])
      @mock_http_response.stub!(:[]).with("location").and_return(@default_headers["location"])
      @mock_http_response.stub!(:[]).with("Content-Encoding").and_return(@default_headers["Content-Encoding"])
      @mock_http_response.stub!(:content_length).and_return(1024)
      @mock_http_response.stub!(:body).and_return("asdf")
      @mock_http_response.stub!(:get_fields).with('set-cookie').and_return(["session=al98axx; expires=Fri, 31-Dec-1999 23:58:23", "query=rubyscript; expires=Fri, 31-Dec-1999 23:58:23"])
      @mock_http_response.stub!(:to_hash).and_return(@default_headers)
      
      @mock_http_redirect_response.stub!(:code).and_return(301)
      @mock_http_redirect_response.stub!(:content_type).and_return("text/html")
      @mock_http_redirect_response.stub!(:headers).and_return(@default_headers)
      # @mock_http_redirect_response.stub!(:[]).with("Content-Type").and_return(@default_headers["Content-Type"])
      # @mock_http_redirect_response.stub!(:[]).with("location").and_return("http://redirected-to.com/redirect2.html")
      # @mock_http_redirect_response.stub!(:[]).with("Content-Encoding").and_return(@default_headers["Content-Encoding"])
      @mock_http_redirect_response.stub!(:content_length).and_return(2048)
      @mock_http_redirect_response.stub!(:body).and_return("redirected body")
      @mock_http_redirect_response.stub!(:get_fields).with('set-cookie').and_return(["session=al98axx; expires=Fri, 31-Dec-1999 23:58:23", "query=rubyscript; expires=Fri, 31-Dec-1999 23:58:23"])
      @mock_http_redirect_response.stub!(:to_hash).and_return(@default_headers)
      
      @mock_http_redirect_response2.stub!(:code).and_return(301)
      @mock_http_redirect_response2.stub!(:content_type).and_return("text/html")
      @mock_http_redirect_response2.stub!(:[]).with("Content-Type").and_return(@default_headers["Content-Type"])
      @mock_http_redirect_response2.stub!(:[]).with("location").and_return("http://redirected-to.com/redirected.html")
      @mock_http_redirect_response2.stub!(:[]).with("Content-Encoding").and_return(@default_headers["Content-Encoding"])
      @mock_http_redirect_response2.stub!(:content_length).and_return(2048)
      @mock_http_redirect_response2.stub!(:body).and_return("redirected body")
      @mock_http_redirect_response2.stub!(:get_fields).with('set-cookie').and_return(["session=al98axx; expires=Fri, 31-Dec-1999 23:58:23", "query=rubyscript; expires=Fri, 31-Dec-1999 23:58:23"])
      @mock_http_redirect_response2.stub!(:to_hash).and_return(@default_headers)
    }


  end
  
