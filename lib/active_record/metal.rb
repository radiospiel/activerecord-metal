require "active_record"

class ActiveRecord::Metal
  attr :connection
  
  def initialize(connection = ActiveRecord::Base.connection)
    @connection = connection
    
    extend implementations
  end
  
  private
  
  def implementations
    case connection
    when ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      require_relative "metal/postgresql"
      ActiveRecord::Metal::Postgresql
    end
  end
end

require "expectation/assertions"

module ActiveRecord::Metal::Etest
  include Expectation::Assertions
  
  def metal
    @metal ||= ActiveRecord::Metal.new
  end
  
  def test_pg_connection
    expect! metal.connection => ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    expect! metal.is_a?(ActiveRecord::Metal::Postgresql)
  end
end

