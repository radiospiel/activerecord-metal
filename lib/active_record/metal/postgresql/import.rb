module ActiveRecord::Metal::Postgresql::Import
  #
  # Import a number of records into a table.
  # records is either an Array of Hashes or an Array of Arrays.
  # In the latter case each record *must* match the order of columns
  # in the table.
  def import(table_name, records, options = {})
    benchmark "INSERT #{records.length} records into #{table_name}" do
      expect! table_name => /^\S+$/
      expect! records.first => [ nil, Hash, Array ]

      importer = records.first.is_a?(Hash) ? :import_hashes : :import_arrays

      case records.length
      when 0 then :nop
      when 1 then               send(importer, table_name, records, options)
      else        transaction { send(importer, table_name, records, options) }
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
      exec stmt, *record.values_at(*keys)
    end
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
      exec stmt, *record
    end
  ensure
    unprepare(stmt)
  end
end

module ActiveRecord::Metal::Postgresql::Import::Etest
  include ActiveRecord::Metal::EtestBase
  
  # metal.ask "CREATE TABLE test(num INTEGER, num2 INTEGER, str1 VARCHAR)"

  def test_import_none
    metal.ask "DELETE FROM test"
    metal.import "test", []
    expect! metal.ask("SELECT COUNT(*) FROM test") => 0
  end

  def test_import_array
    metal.ask "DELETE FROM test"
    metal.import "test", [[1,2,"one"]], :columns => %w(num num2 str1)
    expect! metal.ask("SELECT COUNT(*) FROM test") => 1
  end
  
  def test_import_hashes
    metal.ask "DELETE FROM test"
    metal.import "test", [ num: 1, num2: 1, str1: "one" ]
    expect! metal.ask("SELECT COUNT(*) FROM test") => 1
  end
end
