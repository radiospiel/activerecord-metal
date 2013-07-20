module ActiveRecord::Metal::Postgresql::PreparedQueries
  def prepare(sql)
    prepared_statements[sql]
  rescue PG::Error
    log_error $!, sql
    raise
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
  rescue PG::Error
    log_error $!, query
    raise
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

  # Name for a prepared statement. The name is derived from the SQL code, but is also
  # specific for this ActiveRecord::Metal.instance.
  def prepared_statement_name(sql)
    key = "#{object_id}-#{sql}"
    "pg_metal_#{Digest::MD5.hexdigest(key)}"
  end
end

module ActiveRecord::Metal::Postgresql::PreparedQueries::Etest
  include ActiveRecord::Metal::EtestBase

  def test_prepared_queries_housekeeping
    # if we have two metal adapters working on the same connection,
    # one must not affect the prepared queries of the other.
    alloys = metal.ask "SELECT COUNT(*) FROM alloys WHERE id >= $1", 0
    other_metal = ActiveRecord::Metal.new
    expect! other_metal.ask("SELECT COUNT(*) FROM alloys WHERE id >= $1", 0) => alloys
    expect! metal.ask("SELECT COUNT(*) FROM alloys WHERE id >= $1", 0) => alloys
  end

  def test_prepared_query_fails_during_import
    metal.ask "DELETE FROM alloys"
    
    # If a prepared query fails, eg. during an import, the transaction
    # will fail and cancelled. This also means that there is no longer
    # a way to clean up the prepared query in the transaction, because
    # this fails with a "transaction failed already" error.
    query = metal.prepare "INSERT INTO alloys (id, num) VALUES($1, $1)"

    assert_raise(PG::Error) {  
      records = [ [1,1], [1,1] ]
      metal.import "alloys", records, :columns => [ "id", "num"]
    }

    # Note: after that point we can no longer do anything in this test.
    # This is because a test is wrapped in a transaction, and this
    # transaction is aborted.
    # expect! metal.count("alloys") => 0
  end
  
  def test_transaction_aborted
    metal.ask "DELETE FROM alloys"
    metal.transaction do
      metal.ask "INSERT INTO alloys (id, num) VALUES($1, $1)", 1
      
      # "duplicate key value violates unique constraint"
      assert_raise(PG::Error) {  
        metal.ask "INSERT INTO alloys (id, num) VALUES($1, $1)", 1
      }

      # "current transaction is aborted"
      assert_raise(PG::Error) {  
        metal.ask "INSERT INTO alloys (id, num) VALUES($1, $1)", 2
      }
    end
  end
end
