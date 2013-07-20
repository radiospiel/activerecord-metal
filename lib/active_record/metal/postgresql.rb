require "digest/md5"

module ActiveRecord::Metal::Postgresql
  # -- initialisation -------------------------------------------------
  
  attr :pg_types, :pg_conn

  def initialize_implementation
    @pg_conn = connection.instance_variable_get("@connection")
    @pg_types = load_pg_types
    
    # unprepare_all
    
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
require_relative "postgresql/prepared_queries"
require_relative "postgresql/exec"
require_relative "postgresql/import"

module ActiveRecord::Metal::Postgresql
  include Queries, PreparedQueries, Exec, Import
end
