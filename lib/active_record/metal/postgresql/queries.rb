
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
    
    def initialize(metal, sql, *args)
      @metal = metal
      
      if args.empty?
        @pg_result = metal.connection.execute(sql)
      else
        name = metal.send(:prepare_query, sql)
        @pg_result = metal.send(:exec_prepared, name, *args)
        metal.send(:unprepare_query, sql)
      end
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
