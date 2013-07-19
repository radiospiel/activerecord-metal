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
  
  public

  def has_table?(name)
    ask "SELECT 't'::BOOLEAN FROM pg_tables WHERE tablename=$1", name
  end
  
  def has_index?(name)
    ask "SELECT 't'::BOOLEAN FROM pg_indexes WHERE indexname=$1", name
  end
end

require_relative "postgresql/conversions"
require_relative "postgresql/queries"
require_relative "postgresql/import"

module ActiveRecord::Metal::Postgresql
  include Queries
  include Import
end
