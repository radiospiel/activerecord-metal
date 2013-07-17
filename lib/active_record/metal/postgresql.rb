require "digest/md5"

module ActiveRecord::Metal::Postgresql
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
  
  public
  
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
  
  def unprepare_all  
    exec_ "DEALLOCATE PREPARE ALL"
    @prepared_statements_by_name = @prepared_statements = nil
  end
  
  private
  
  # -- raw queries ----------------------------------------------------
  
  def exec_(sql)
    # STDERR.puts "--> #{sql}"
    pg_conn.exec sql
  end

  def exec_prepared(sym, *args)
    args = args.map do |arg|
      if arg.is_a?(Hash)
        ActiveRecord::Metal::Postgresql::Conversions::HStore.escape(arg)
      else
        arg
      end
    end

    pg_conn.exec_prepared(sym.to_s, args)
  end
  
  def prepared_statement_name(sql)
    "pg_metal_#{Digest::MD5.hexdigest(sql)}"
  end

  # -- initialisation -------------------------------------------------
  
  attr :pg_types, :pg_conn

  def initialize_implementation
    @pg_conn = connection.instance_variable_get("@connection")
    @pg_types = load_pg_types
    
    unprepare_all
    
    name, installed_version = exec("SELECT name, installed_version FROM pg_available_extensions WHERE name='hstore'").first
    exec_ "CREATE EXTENSION IF NOT EXISTS hstore" unless installed_version
  end
  
  def load_pg_types
    Hash.new("_default").tap do |hsh|
      hsh[17] = "bytea"

      connection.select_all("SELECT typelem, typname FROM pg_type").
      each do |record|
        typelem, typname = record.values_at "typelem", "typname"
        hsh[typelem.to_i] = typname
      end
    end
  end
end

require_relative "postgresql/conversions"
require_relative "postgresql/queries"
require_relative "postgresql/import"

module ActiveRecord::Metal::Postgresql
  include Queries
  include Import
end
