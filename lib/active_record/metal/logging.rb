module ActiveRecord::Metal::Logging
  SELF = self
  
  @@logger = nil
  
  def self.logger
    @@logger ||= ActiveRecord::Base.logger
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def log_benchmark(severity, runtime, msg)
    return unless logger = SELF.logger

    threshold = ActiveRecord::Base.auto_explain_threshold_in_seconds
    if threshold
      return if runtime < threshold
      severity = :info if severity == :debug
    end

    runtime = "%.1f msecs" % (runtime * 1000)

    unless msg.gsub!(/\{\{runtime\}\}/, runtime)
      msg = "#{runtime} #{msg}"
    end

    logger.send severity, msg
  end
  
  def benchmark(msg, severity = :info)
    started_at = Time.now
    yield
  ensure
    log_benchmark severity, runtime, msg
  end
end