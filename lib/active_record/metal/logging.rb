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
    @benchmark_depth ||= 0
    return if @benchmark_depth > 0
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
    @benchmark_depth ||= 0
    @benchmark_depth += 1
    started_at = Time.now
    yield
  ensure
    @benchmark_depth -= 1
    log_benchmark severity, Time.now - started_at, msg
  end
  
  private
  
  def log_error(exception, query, *args)
    unless args.empty?
      args = "w/#{args.map(&:inspect).join(", ")}"
    else
      args = ""
    end

    ActiveRecord::Metal.logger.error "#{exception} on #{resolve_query(query)} #{args}"
  end
end
