module ActiveRecord::Metal::Postgresql
  private

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

  def initialize_implementation
    @pg_types = load_pg_types
  end

  attr :pg_types
end

require_relative "postgresql/conversions"

module ActiveRecord::Metal::Postgresql::Queries
  class Executor < Array
    class Row < Array
      attr :columns, :types

      def initialize(values, columns, types)
        @columns, @types = columns, types
        replace(values)
      end
    end

    attr :columns, :types
    
    def initialize(metal, sql)
      @metal = metal
      @pg_result = metal.connection.execute(sql)
      @current_row = 0

      setup_colums
      setup_types
    end

    def next_row
      return nil if @current_row >= @pg_result.ntuples
      
      values = 0.upto(@pg_result.nfields-1).map do |column_number|
        data = @pg_result.getvalue(@current_row, column_number)
        data = @converters[column_number].call(data) if data
        data
      end

      create_row(values)
    ensure
      @current_row += 1
    end
    
    private
    
    def create_row(values)
      Row.new values, columns, types
    end
    
    def setup_colums
      @columns = (0 ... @pg_result.nfields).map { |i| @pg_result.fname(i) }
    end
    
    Conversions = ActiveRecord::Metal::Postgresql::Conversions

    def setup_types
      metal_pg_types = @metal.send(:pg_types)

      pg_types = (0 ... @pg_result.nfields).map do |i|
        pg_type_id = @pg_result.ftype(i)
        pg_type = metal_pg_types[pg_type_id] || raise("Unknown pg_type_id: #{pg_type_id}")
        pg_type.gsub(/\d+$/, "").to_sym
      end
      
      # -- ruby types -------------------------------------------------

      @types = pg_types.map do |pg_type| 
        Conversions.resolve_type(pg_type)
      end

      # -- converters -------------------------------------------------

      unescape_bytea = lambda { |s| connection.unescape_bytea(s) }

      @converters = pg_types.map do |pg_type|
        if pg_type == :bytea
          unescape_bytea
        else
          Conversions.method(pg_type)
        end
      end
    end
  end

  def exec(sql, *args, &block)
    executor = Executor.new(self, sql, *args)

    rows = []
    while row = executor.next_row
      yield row if block
      rows << row
    end

    executor.send :create_row, rows
  end
  
  def ask(sql, *args)
    first_row = nil
    
    catch(:received_first_row) do
      exec(sql, *args) do |row|
        first_row = row
        throw :received_first_row
      end
    end
    
    first_row && first_row.first
  end
end

module ActiveRecord::Metal::Postgresql
  include Queries
end

module ActiveRecord::Metal::Postgresql::Etest
  include Expectation::Assertions
  
  def metal
    @metal ||= ActiveRecord::Metal.new
  end
  
  def test_initialisation
    # Make sure types are loaded during initialisation
    expect! metal.send(:pg_types).values.include?("_int8")
  end
  
  def test_simple_query
    expect! metal.ask("SELECT 1") => 1
    result = metal.exec("SELECT 1 AS number")
    assert_equal(result, [[1]])
    assert_equal(result.types, [Numeric])
    assert_equal(result.columns, ["number"])
  end
end
