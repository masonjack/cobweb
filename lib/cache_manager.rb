
module CacheManager

  def store(key, value)
    raise "Not implemented"
  end

  def get(key)
    raise "Not implemented"
  end

  def in_cache?(key)
    raise "Not implemented"    
  end
  
end


class RedisCacheManager
  include CacheManager

  def initialize(options = {} )
    @timeout = options[:cache]
    if options.has_key? :crawl_id
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{options[:crawl_id]}", :redis => Redis.new(options))
    else
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}", :redis => Redis.new(options))
    end
  end

  def store(key, data)
    @redis.set(key, Marshal.dump(data))
    @redis.expire key, @timeout.to_i
  end

  def get(key)
    HashUtil.deep_symbolize_keys(Marshal.load(@redis.get(key)))
  end

  def in_cache?(key)
    return true if @redis.get(key)
    false
  end
  
end
