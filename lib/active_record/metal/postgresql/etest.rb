# coding: utf-8

module ActiveRecord::Metal::Postgresql::Etest
  include ActiveRecord::Metal::EtestBase
  
  def test_simple_query
    expect! metal.ask("SELECT 1") => 1
    result = metal.exec("SELECT 1 AS number")
    assert_equal(result, [[1]])
    assert_equal(result.types, [Numeric])
    assert_equal(result.columns, ["number"])
  end

  def test_null_query
    expect! metal.ask("SELECT 1 AS number WHERE FALSE") => nil
    result = metal.exec("SELECT 1 AS number WHERE FALSE")
    assert_equal(result, [])
    assert_equal(result.types, [Numeric])
    assert_equal(result.columns, ["number"])
  end

  def test_positioned_parameters
    expect! metal.ask("SELECT 1 AS number WHERE 1=$1", 1) => 1
    assert_equal metal.exec("SELECT 1 AS number WHERE 1=$1", 1), [[1]]
    assert_equal metal.exec("SELECT 1 AS value WHERE 1=$1", 1), [[1]]
    assert_equal metal.exec("SELECT 1 AS value WHERE 1=$1", "1"), [[1]]
  end
  
  def test_exceptions
    assert_raise() {  
        metal.exec("SELECT 1 FROM unknown")
    }
  end

  def import_performance(count)
    return if ENV["ARM_ENV"] == "test" && count > 10
    
    # -- setup records ------------------------------------------------

    records = 1.upto(count).map do |rec|
      {
        num:    rand(100000),
        num2:   rand(100000),
        str1:   "alloy_#{Digest::MD5.hexdigest(rand(100000).to_s)}"
      }
    end

    id = 0
    values = records.map { |rec| 
      [ (id += 1) ] + rec.values_at(:num, :num2, :str1)
    }

    # -- run tests ----------------------------------------------------

    metal.ask "DELETE FROM alloys"

    metal.import "alloys", records
    metal.ask "DELETE FROM alloys"

    metal.import "alloys", values
    metal.ask "DELETE FROM alloys"
    
    ActiveRecord::Metal.benchmark "Import #{count} hashes via ActiveRecord::Base" do
      Alloy.transaction do
        records.each do |record|
          Alloy.create! record
        end
      end
    end

    metal.ask "DELETE FROM alloys"
  end
  
  def test_import_performance
    import_performance(1)
    import_performance(100)
    import_performance(10000)
  end
  
  def test_timestamp(mode = "with time zone")
    metal.ask "DROP TABLE IF EXISTS timetable"
    metal.ask "CREATE TABLE IF NOT EXISTS timetable (name varchar, created_at timestamp #{mode})"

    now = Time.at(Time.now.to_i)
    back = Time.parse("2010-10-01 12:00:00")

    metal.ask "INSERT INTO timetable VALUES($1, $2)", "now", now
    metal.ask "INSERT INTO timetable VALUES($1, $2)", "back", back

    expect! metal.ask("SELECT created_at FROM timetable WHERE name=$1", "now") => now
    expect! metal.ask("SELECT created_at FROM timetable WHERE name=$1", "back") => back
  end

  def test_timestamp_without_tz
    test_timestamp "without time zone"
  end
end
