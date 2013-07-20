module ActiveRecord::Metal::Postgresql::Exec
  private

  # -- raw queries ----------------------------------------------------

  def exec_(sql)
    # STDERR.puts "exec_ --> #{sql}"
    result = pg_conn.exec(sql)
    check result, sql
  end

  def exec_prepared(sym, *args)
    # STDERR.puts "exec_prepared: #{sym.inspect}"
    args = args.map do |arg|
      if arg.is_a?(Hash)
        ActiveRecord::Metal::Postgresql::Conversions::HStore.escape(arg)
      else
        arg
      end
    end

    result = pg_conn.exec_prepared(sym.to_s, args)
    check result, sym, *args
  end

  def check(result, query, *args)
    result.check
    result
  rescue 
    unless args.empty?
      args = "w/#{args.map(&:inspect).join(", ")}"
    else
      args = ""
    end

    ActiveRecord::Metal.logger.error "#{$!.class.name}: #{$!} on #{resolve_query(query)} #{args}"
    raise
  end
end
