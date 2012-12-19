require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cobweb, :local_only => true do

  before(:all) do
    #store all existing resque process ids so we don't kill them afterwards
    @existing_processes = `ps aux | grep resque | grep -v grep | grep -v resque-web | awk '{print $2}'`.split("\n")

    # START WORKERS ONLY FOR CRAWL QUEUE SO WE CAN COUNT ENQUEUED PROCESS AND FINISH QUEUES
    puts "Starting Workers... Please Wait..."
    # `mkdir log`
    # `mkdir tmp/pids`
    # # PIDFILE=./tmp/pids/resque.pid
    # io = IO.popen("nohup rake resque:workers COUNT=10 QUEUE=cobweb_crawl_job,cobweb_content_processing > log/output.log &")
     puts "Workers Started."
    


  end

  before(:each) do
    @base_url = "http://en.wikipedia.org/"
    @base_page_count = 77
    
    clear_queues
  end



  before(:each) do
    # 
    @request = { :url=>"http://en.wikipedia.org/", :timeout=>500, :cache=>1200, :quiet=>false, :debug=>true, :crawl_finished_queue=>"CrawlFinishedJob", :crawl_finished_file=>"/Users/malcolm/dev/ganymede/lib/crawl_finished_job", :url_processor=>"ProcessJob", :processing_file=>"/Users/malcolm/dev/ganymede/lib/process_job", :direct_call_process_job=>true, :enqueue_counter_namespace=>"ganymede-90fa34cba9a910fbf7d97e00bbe633d681d590ff", :enqueue_counter_key=>"process_job", :enqueue_counter_field=>"queued", :ignore_default_tags=>true, :additional_tags=>{:links=>[["a[href]", "href"], ["frame[src]", "src"], ["meta[@http-equiv=\"refresh\"]", "content"], ["link[href]:not([rel])", "href"], ["area[href]", "href"]]}, :valid_mime_types=>["text/*", "application/xhtml+xml", "application/javascript", "text/css"], :redis_options=>{:host=>"localhost"}, :source_id=>1, :spelling_likely_errors=>{:valid_words=>""}, :spelling_unlikely_errors=>{:valid_words=>""}, :check_character_set=>{:charset_expected=>""}, :poor_link_text=>{:non_descriptive_text=>"read more, more, click here"}, :source=>{:base_url=>"http://en.wikipedia.org/", :follow_redirects=>true, :internal_urls=>["http://en.wikipedia.org/"], :external_urls=>[], :crawl_limit=>100}, :base_url=>"http://en.wikipedia.org/", :follow_redirects=>true, :internal_urls=>["http://en.wikipedia.org/"], :external_urls=>[], :crawl_limit=>100, :crawl_limit_by_page=>true, :use_encoding_safe_process_job=>false, :redirect_limit=>10, :additional_url_processors=>[], :first_page_redirect_internal=>true, :text_mime_types=>["text/*", "application/xhtml+xml"], :obey_robots=>false, :user_agent=>"cobweb/0.0.75 (ruby/1.9.3 nokogiri/1.5.5)", :cache_manager=>"DummyCache", :processing_queue=>"UrlProcessingJob"} 

    @request[:crawl_id] = Digest::SHA1.hexdigest("#{Time.now.to_i}.#{Time.now.usec}")
    
    # @request = {
    #   :crawl_id => Digest::SHA1.hexdigest("#{Time.now.to_i}.#{Time.now.usec}"),
    #   :crawl_limit => 10000,
    #   :follow_redirects => true,
    #   :redirect_limit => 10,
    #   :quiet => false,
    #   :debug => true,
    #   :cache => nil,
    #   :additional_url_processors => ["LocalFilePersistanceProcessor"],
    #   :crawl_finished_queue => "CobwebFinishedJob",
    #   :valid_mime_types => ["text/*"]
    # }
    @cobweb = Cobweb.new @request
  end

  it "should eventually finish" do
    crawl = @cobweb.start(@base_url)
    #sleep 60
    wait_for_crawl_finished crawl[:crawl_id], 4000

  end
  


  after(:all) do

    @all_processes = `ps aux | grep resque | grep -v grep | grep -v resque-web | awk '{print $2}'`.split("\n")
    command = "kill -9 #{(@all_processes - @existing_processes).join(" ")}"
    IO.popen(command)
    
    clear_queues
  end

  
end



def wait_for_crawl_finished(crawl_id, timeout=2000)
  @counter = 0
  start_time = Time.now
  while(running?(crawl_id) && Time.now < start_time + timeout) do
    puts("crawl #{crawl_id} is running and not complete")
    sleep 0.5
  end
  if Time.now > start_time + timeout
    raise "End of crawl not detected"
  end
end

def running?(crawl_id)
  spider_items = Resque.size("cobweb_process_job") || 0
  process_items = Resque.size("cobweb_content_processing") || 0

  size = spider_items.size + process_items
  return true if size > 0
  return false
  
end

def clear_queues
  Resque.queues.each do |queue|
    Resque.remove_queue(queue)
  end

  Resque.size("cobweb_process_job").should == 0
  Resque.size("cobweb_finished_job").should == 0
  Resque.peek("cobweb_process_job", 0, 200).should be_empty
end

