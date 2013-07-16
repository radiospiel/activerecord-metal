require "digest/md5"

module ActiveRecord::Metal::Postgresql
  private

  # -- raw queries ----------------------------------------------------
  
  def exec_(sql)
    pg_conn.exec sql
  end

  def exec_prepared(name, *args)
    pg_conn.exec_prepared(name, args)
  end
  
  def prepare_query(sql)
    name = prepared_statement_name(sql)
    pg_conn.prepare(name, sql)
    name
  end
  
  def unprepare_query(sql)
    name = prepared_statement_name(sql)
    exec_("DEALLOCATE PREPARE #{name}")
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

module ActiveRecord::Metal::Postgresql
  include Queries
end
