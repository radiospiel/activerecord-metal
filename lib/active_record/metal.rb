require "active_record"

class ActiveRecord::Metal
  attr :connection
  
  def initialize(connection = ActiveRecord::Base.connection)
    @connection = connection
    
    extend implementation
    
    initialize_implementation
  end
  
  private
  
  # To be overridden by the implementation
  def initialize_implementation
  end
  
  def implementation
    case connection
    when ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      require_relative "metal/postgresql"
      ActiveRecord::Metal::Postgresql
    end
  end
end


require_relative "metal/transaction"

class ActiveRecord::Metal
  include Transaction
end

module ActiveRecord::Metal::EtestBase
  def self.included(_)
    require "expectation/assertions"
    include Expectation::Assertions
  end
  
  def metal
    @metal ||= ActiveRecord::Metal.new
  end
end

module ActiveRecord::Metal::Etest
  include ActiveRecord::Metal::EtestBase

  def metal
    @metal ||= ActiveRecord::Metal.new
  end

  def test_pg_connection
    expect! metal.connection => ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    expect! metal.is_a?(ActiveRecord::Metal::Postgresql)
  end
end
