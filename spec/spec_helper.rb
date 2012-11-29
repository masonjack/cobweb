require 'simplecov'
SimpleCov.start

require File.expand_path(File.dirname(__FILE__) + '/../lib/cobweb')
require File.expand_path(File.dirname(__FILE__) + '/../spec/samples/sample_server')
require 'mock_redis'
require 'thin' if ENV["TRAVIS_RUBY_VERSION"].nil?

# code coverage tooling support
# Sets up the environment as test so that exceptions are raised
ENVIRONMENT = "test"
APP_ROOT = File.expand_path(File.dirname(__FILE__) + '/../')

RSpec.configure do |config|
  
  unless ENV["TRAVIS_RUBY_VERSION"].nil?
    config.filter_run_excluding :local_only => true
  end
  
  config.before(:all) {
    # START THIN SERVER TO HOST THE SAMPLE SITE FOR CRAWLING
    @thin = nil
    Thread.new do
      @thin = Thin::Server.start("0.0.0.0", 3532, SampleServer.app)
    end
  
    # WAIT FOR START TO COMPLETE
    sleep 1
  }
  


end

class DummyCache
  include CacheManager
  def initialize(opts)
  end
  
  def get(key)
    nil
  end
  def set(key,value)
  end
  def in_cache?(key)
    false
  end
end

class SimpleHashCache
  include CacheManager
  attr_accessor :cache
  
  def initialize(opts)
    @cache = Hash.new
  end
  
  def get(key)
    @cache[key]
  end

  def set(key, value)
    @cache[key] = value
  end

  def in_cache?(key)
    @cache.has_key?(key)
  end
end



