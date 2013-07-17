require "digest/md5"

module ActiveRecord::Metal::Postgresql
  def prepare(sql)
    name = prepared_statement_name(sql)
    pg_conn.prepare(name, sql)
    name.to_sym
  end

  def unprepare(query)
    expect! query => [ Symbol, String ]
    case query
    when Symbol
      exec_("DEALLOCATE PREPARE #{query}")
    when String
      name = prepared_statement_name(query)
      exec_("DEALLOCATE PREPARE #{name}")
    end
  end
  
  private

  # -- raw queries ----------------------------------------------------
  
  def exec_(sql)
    pg_conn.exec sql
  end

  def exec_prepared(sym, *args)
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
    
    exec_("DEALLOCATE PREPARE ALL")
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
