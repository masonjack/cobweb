
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
    if options.has_key? :crawl_id
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}-#{options[:crawl_id]}", :redis => Redis.new(options[:redis_options]))
    else
      @redis = Redis::Namespace.new("cobweb-#{Cobweb.version}", :redis => Redis.new(options[:redis_options]))
    end
  end

  def store(key, data)
    @redis.set(key, Marshal.dump(content))
    @redis.expire key, @options[:cache].to_i
  end

  def get(key)
    HashUtil.deep_symbolize_keys(Marshal.load(@redis.get(unique_id)))
  end

  def in_cache?(key)
    return true if redis.get(key)
    false
  end
  
end
