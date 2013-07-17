module ActiveRecord::Metal::Postgresql::Queries
  class ArrayWithTypeInfo < Array
    attr :columns, :types

    def initialize(values, columns, types)
      @columns, @types = columns, types
      replace(values)
    end
  end

  class Result < Array
    attr :columns, :types
    
    def initialize(metal, pg_result, *args)
      @metal, @pg_result = metal, pg_result
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

      ArrayWithTypeInfo.new values, columns, types
    ensure
      @current_row += 1
    end
    
    private
    
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

      pg_conn = @metal.send(:pg_conn)
      unescape_bytea = lambda { |s| pg_conn.unescape_bytea(s) }

      @converters = pg_types.map do |pg_type|
        if pg_type == :_bytea
          unescape_bytea
        else
          Conversions.method(pg_type)
        end
      end
    end
  end

  def exec(sql, *args, &block)
    started_at = Time.now
    
    # prepared queries - denoted by symbols - are executed as such, and
    # not cleaned up. A caller can get a prepared query by calling 
    # metal.prepare.
    if sql.is_a?(Symbol)
      pg_result = exec_prepared(sql, *args)
    elsif args.empty?
      pg_result = exec_(sql)
    else
      name = prepare(sql)
      pg_result = exec_prepared(name, *args)
      unprepare(sql)
    end

    result = Result.new(self, pg_result, *args)

    rows = []
    while row = result.next_row
      yield row if block
      rows << row
    end

    ArrayWithTypeInfo.new rows, result.columns, result.types
  ensure
    log_benchmark :debug, Time.now - started_at, 
                  "SQL: {{runtime}} %s %s" % [ sql.is_a?(Symbol) ? "[P]" : "   ", resolve_query(sql) ]
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

module ActiveRecord::Metal::Postgresql::Queries::Etest
  include ActiveRecord::Metal::EtestBase

  def test_benchmark
    metal.ask("SELECT 1")
    metal.ask("SELECT 1 WHERE 1=$1", 1)
    query = metal.prepare("SELECT 1 WHERE 1=$1")
    metal.ask(query, 1)
    metal.unprepare(query)
  end
end

