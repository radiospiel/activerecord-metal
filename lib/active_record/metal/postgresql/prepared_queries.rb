module ActiveRecord::Metal::Postgresql::PreparedQueries
  def prepare(sql)
    prepared_statements[sql]
  end

  def unprepare(query)
    expect! query => [ Symbol, String ]
    case query
    when Symbol
      exec_("DEALLOCATE PREPARE #{query}")
      sql = prepared_statements_by_name.delete query
      prepared_statements.delete sql
    when String
      name = prepared_statement_name(query)
      exec_("DEALLOCATE PREPARE #{name}")
      prepared_statements.delete query
      prepared_statements_by_name.delete name
    end
  end

  private

  def prepared_statements_by_name
    @prepared_statements_by_name ||= {}
  end

  def prepared_statements
    @prepared_statements ||= Hash.new { |hsh, sql| hsh[sql] = _prepare(sql) }
  end

  def resolve_query(query)
    query.is_a?(Symbol) ? prepared_statements_by_name[query] : query
  end

  def _prepare(sql)
    name = prepared_statement_name(sql)
    pg_conn.prepare(name, sql)
    name = name.to_sym
    prepared_statements_by_name[name] = sql
    name
  end

  def prepared_statement_name(sql)
    key = "#{object_id}-#{sql}"
    "pg_metal_#{Digest::MD5.hexdigest(key)}"
  end
end
