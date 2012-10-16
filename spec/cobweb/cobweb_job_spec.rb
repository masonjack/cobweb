require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cobweb, :local_only => true do

  before(:all) do
    #store all existing resque process ids so we don't kill them afterwards
    @existing_processes = `ps aux | grep resque | grep -v grep | grep -v resque-web | awk '{print $2}'`.split("\n")

    # START WORKERS ONLY FOR CRAWL QUEUE SO WE CAN COUNT ENQUEUED PROCESS AND FINISH QUEUES
    puts "Starting Workers... Please Wait..."
    `mkdir log`
    io = IO.popen("nohup rake resque:workers PIDFILE=./tmp/pids/resque.pid COUNT=3 QUEUE=cobweb_crawl_job > log/output.log &")
    puts "Workers Started."

  end

  before(:each) do
    @base_url = "http://localhost:3532/"
    @base_page_count = 77

    clear_queues
  end

  describe "when crawl is cancelled" do
    before(:each) do
      @request = {
        :crawl_id => Digest::SHA1.hexdigest("#{Time.now.to_i}.#{Time.now.usec}"),
        :crawl_limit => nil,
        :quiet => false,
        :debug => false,
        :cache => nil
      }
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{@request[:crawl_id]}", Redis.new)
      @cobweb = Cobweb.new @request
    end
    it "should not crawl anything if nothing has started" do
      crawl = @cobweb.start(@base_url)
      crawl_obj = CobwebCrawlHelper.new(crawl)
      crawl_obj.destroy
      @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
      wait_for_crawl_finished crawl[:crawl_id]
      @redis.get("crawl_job_enqueued_count").to_i.should == 0
    end

    it "should not complete the crawl when cancelled" do
      crawl = @cobweb.start(@base_url)
      crawl_obj = CobwebCrawlHelper.new(crawl)
      sleep 6
      crawl_obj.destroy
      @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
      wait_for_crawl_finished crawl[:crawl_id]
      @redis.get("crawl_job_enqueued_count").to_i.should > 0
      @redis.get("crawl_job_enqueued_count").to_i.should_not == @base_page_count
    end

  end
  describe "with no crawl limit" do
    before(:each) do
      @request = {
        :crawl_id => Digest::SHA1.hexdigest("#{Time.now.to_i}.#{Time.now.usec}"),
        :crawl_limit => nil,
        :quiet => false,
        :debug => false,
        :cache => nil
      }
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{@request[:crawl_id]}", Redis.new)

      @cobweb = Cobweb.new @request
    end

    it "should crawl entire site" do
      crawl = @cobweb.start(@base_url)
      @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
      wait_for_crawl_finished crawl[:crawl_id]
      @redis.get("crawl_job_enqueued_count").to_i.should == @base_page_count
      @redis.get("crawl_finished_enqueued_count").to_i.should == 1
    end
    it "detect crawl finished once" do
      crawl = @cobweb.start(@base_url)
      @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
      wait_for_crawl_finished crawl[:crawl_id]
      @redis.get("crawl_job_enqueued_count").to_i.should == @base_page_count
      @redis.get("crawl_finished_enqueued_count").to_i.should == 1
    end
  end
  describe "with limited mime_types" do
    before(:each) do
      @request = {
        :crawl_id => Digest::SHA1.hexdigest("#{Time.now.to_i}.#{Time.now.usec}"),
        :quiet => true,
        :cache => nil,
        :valid_mime_types => ["text/html"]
      }
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{@request[:crawl_id]}", Redis.new)
      @cobweb = Cobweb.new @request
    end

    it "should only crawl html pages" do
      crawl = @cobweb.start(@base_url)
      @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
      wait_for_crawl_finished crawl[:crawl_id]
      @redis.get("crawl_job_enqueued_count").to_i.should == 8

      mime_types = Resque.peek("cobweb_process_job", 0, 100).map{|job| job["args"][0]["mime_type"]}
      mime_types.count.should == 8
      mime_types.map{|m| m.should == "text/html"}
      mime_types.select{|m| m=="text/html"}.count.should == 8
    end

  end
  describe "with a crawl limit" do
    before(:each) do
      @request = {
        :crawl_id => Digest::SHA1.hexdigest("#{Time.now.to_i}.#{Time.now.usec}"),
        :quiet => true,
        :cache => nil
      }
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{@request[:crawl_id]}", Redis.new)
    end

    describe "limit to 1" do
      before(:each) do
        @request[:crawl_limit] = 1
        @cobweb = Cobweb.new @request
      end

      it "should not crawl the entire site" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_job_enqueued_count").to_i.should_not == @base_page_count
      end
      it "should only crawl 1 page" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_job_enqueued_count").to_i.should == 1
      end
      it "should notify of crawl finished once" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_finished_enqueued_count").to_i.should == 1
      end
    end

    describe "for pages only" do
      before(:each) do
        @request[:crawl_limit_by_page] = true
        @request[:crawl_limit] = 5
        @cobweb = Cobweb.new @request
      end

      # the following describes when we want all the assets of a page, and the page itself, but we only want 5 pages
      it "should only use html pages towards the crawl limit" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        mime_types = Resque.peek("cobweb_process_job", 0, 200).map{|job| job["args"][0]["mime_type"]}
        Resque.peek("cobweb_process_job", 0, 200).count.should > 5
        mime_types.select{|m| m=="text/html"}.count.should == 5
      end
    end

    describe "limit to 10" do
      before(:each) do
        @request[:crawl_limit] = 10
        @cobweb = Cobweb.new @request
      end

      it "should not crawl the entire site" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_job_enqueued_count").to_i.should_not == @base_page_count
      end
      it "should notify of crawl finished once" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_finished_enqueued_count").to_i.should == 1
      end
      it "should only crawl 10 objects" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_job_enqueued_count").to_i.should == 10
      end
    end

    describe "limit to 100" do
      before(:each) do
        @request[:crawl_limit] = 100
        @cobweb = Cobweb.new @request
      end

      it "should crawl the entire sample site" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_job_enqueued_count").to_i.should == @base_page_count
      end
      it "should notify of crawl finished once" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_finished_enqueued_count").to_i.should == 1
      end
      it "should not crawl 100 pages" do
        crawl = @cobweb.start(@base_url)
        @stat = Stats.new({:crawl_id => crawl[:crawl_id]})
        wait_for_crawl_finished crawl[:crawl_id]
        @redis.get("crawl_job_enqueued_count").to_i.should_not == 100
      end
    end
  end


  after(:all) do

    @all_processes = `ps aux | grep resque | grep -v grep | grep -v resque-web | awk '{print $2}'`.split("\n")
    command = "kill -9 #{(@all_processes - @existing_processes).join(" ")}"
    IO.popen(command)

    clear_queues
  end

end

def wait_for_crawl_finished(crawl_id, timeout=20)
  @counter = 0
  start_time = Time.now
  while(running?(crawl_id) && Time.now < start_time + timeout) do
    sleep 0.5
  end
  if Time.now > start_time + timeout
    raise "End of crawl not detected"
  end
end

def running?(crawl_id)
  status = @stat.get_status
  result = true
  if status == CobwebCrawlHelper::STARTING
    result = true
  else
    if status == @last_stat
      if @counter > 5
        raise "Static status: #{status}"
      else
        @counter += 1
      end
      puts "Static Status.. #{6-@counter}"
    else
      result = status != CobwebCrawlHelper::FINISHED && status != CobwebCrawlHelper::CANCELLED
    end
  end
  @last_stat = @stat.get_status
  result
end

def clear_queues
  Resque.queues.each do |queue|
    Resque.remove_queue(queue)
  end

  Resque.size("cobweb_process_job").should == 0
  Resque.size("cobweb_finished_job").should == 0
  Resque.peek("cobweb_process_job", 0, 200).should be_empty
end
