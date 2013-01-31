require 'resque'


class QueueManager

  def self.queue_batch_job(klass_name, bid, content)
    klass = get_processing_class(klass_name)
    Resque.enqueue_batched_job(klass, bid, content)
  end
  
  def self.queue_job(klass_name, content)
    processing_clazz = get_processing_class(klass_name)
    Resque.enqueue(processing_clazz, content_request)
  end

  
  def self.requeue_job(klass, bid, content)
    Resque.enqueue_batched_job(klass, bid, content)
  end
  

  def self.get_processing_class(klass_name)
    Object::const_get(klass_name)
  end


  def start_processing_class(class_name, content)
    
  end
  
end
