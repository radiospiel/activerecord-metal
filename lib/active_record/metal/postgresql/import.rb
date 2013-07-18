module ActiveRecord::Metal::Postgresql::Import
  #
  # Import a number of records into a table.
  # records is either an Array of Hashes or an Array of Arrays.
  # In the latter case each record *must* match the order of columns
  # in the table.
  def import(table_name, records, options = {})
    return if records.empty?
    importer = records.first.is_a?(Hash) ? :hashes : :arrays

    benchmark "INSERT #{records.length} #{importer} into #{table_name}" do
      expect! table_name => /^\S+$/
      expect! records.first => [ nil, Hash, Array ]

      case records.length
      when 0 then :nop
      when 1 then               send("import_#{importer}", table_name, records, options)
      else        transaction { send("import_#{importer}", table_name, records, options) }
      end
    end
  end

  private
  
  def import_hashes(table_name, records, _)
    keys = records.inject([]) do |ary, record|
      ary | record.keys
    end
    
    keys.each { |key| expect! key => Symbol }
    keys.each { |key| expect! key.to_s => /^\S+$/ }

    values = 1.upto(keys.length).map { |idx| "$#{idx}" }
    
    sql = "INSERT INTO #{table_name}(#{keys.join(",")}) VALUES(#{values.join(",")})"
    stmt = prepare(sql)
    records.each do |record|
      exec_prepared stmt, *record.values_at(*keys)
    end
  rescue
    logger.warn "#{$!.class.name}: #{$!}"
    raise
  ensure
    unprepare(stmt)
  end
  
  def import_arrays(table_name, records, options)
    columns = if options[:columns]
      "(" + options[:columns].join(",") + ")"
    end
    
    values = 1.upto(records.first.length).map { |idx| "$#{idx}" }

    sql = "INSERT INTO #{table_name}#{columns} VALUES(#{values.join(",")})"
    stmt = prepare(sql)
    
    records.each do |record|
      exec_prepared stmt, *record
    end
  rescue
    logger.warn "#{$!.class.name}: #{$!}"
    raise
  ensure
    unprepare(stmt)
  end
end

module ActiveRecord::Metal::Postgresql::Import::Etest
  include ActiveRecord::Metal::EtestBase
  
  # metal.ask "CREATE TABLE test(num INTEGER, num2 INTEGER, str1 VARCHAR)"

  def test_import_none
    metal.ask "DELETE FROM alloys"
    metal.import "alloys", []
    expect! metal.ask("SELECT COUNT(*) FROM alloys") => 0
  end

  def test_import_array
    metal.ask "DELETE FROM alloys"
    metal.import "alloys", [[1,2,"one"]], :columns => %w(num num2 str1)
    expect! metal.ask("SELECT COUNT(*) FROM alloys") => 1
  end

  def test_import_array_wo_columns
    metal.ask "DELETE FROM alloys"
    metal.import "alloys", [[1,1,2,"one"]]
    expect! metal.ask("SELECT COUNT(*) FROM alloys") => 1
  end
  
  def test_import_hashes
    metal.ask "DELETE FROM alloys"
    metal.import "alloys", [ num: 1, num2: 1, str1: "one" ]
    expect! metal.ask("SELECT COUNT(*) FROM alloys") => 1
  end
end

__END__

# This is example code to load a table via COPY FROM
def flush_load(records)
  copy_data = records.map do |name, value, timestamp, payload|
    escaped_payload = PgTypedQueries::Conversions::HStore.escape_without_type(payload, connection) if payload
    escaped_payload ||= "NULL"

    "#{name}|#{value}|#{timestamp.to_i}|#{escaped_payload}\n"
  end.join
  
  # STDERR.puts "Running COPY command with #{copy_data.bytesize} bytes for #{records.length} records"
  
  copy_data = StringIO.new(copy_data)
  
  connection.transaction do
    conn = connection.instance_variable_get "@connection"
    buf = ''
    conn.exec("COPY #{table_name} FROM STDIN WITH DELIMITER '|' NULL 'NULL'")
    begin
      while copy_data.read(256, buf)
        ### Uncomment this to test error-handling for exceptions from the reader side:
        # raise Errno::ECONNRESET, "socket closed while reading"
        # $stderr.puts "  sending %d bytes of data..." % [ buf.length ]
        # $stderr.puts "copy #{buf}"
        until conn.put_copy_data( buf )
          $stderr.puts "	waiting for connection to be writable..."
          sleep 0.1
        end
      end

      # puts "done copying"
    rescue Errno => err
      errmsg = "%s while reading copy data: %s" % [ err.class.name, err.message ]
      conn.put_copy_end(errmsg)
    else
      conn.put_copy_end
      while res = conn.get_result
        $stderr.puts "Result of COPY is: %s" % [ res.res_status(res.result_status) ]
        $stderr.puts res.error_message()
      end
    end
  end
end
