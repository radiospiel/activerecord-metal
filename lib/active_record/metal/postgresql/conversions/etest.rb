# coding: utf-8

module ActiveRecord::Metal::Postgresql::Conversions::Etest
  include ActiveRecord::Metal::EtestBase
  
  def test_numeric_types
    expect! metal.ask("SELECT 1") => 1

    [ "smallint", "integer", "bigint", "decimal", "numeric", "real", "double precision" ].each do |type|
      expect! metal.ask("SELECT 1::#{type}") => 1
    end
  end
  
  def test_special_numbers
    expect! metal.ask("SELECT 'Infinity'::real") => Float::INFINITY
    expect! metal.ask("SELECT '-Infinity'::real") => -Float::INFINITY 

    # Can't test for NAN == NAN
    # expect! metal.ask("SELECT 'NaN'::real") => Float::NAN 
  end

  def test_money
    expect! metal.ask("SELECT 1234::text::money") => 1234.0
  end
  
  def test_strings
    expect! metal.ask("SELECT 'ok'")
    expect! metal.ask("SELECT 'good      '") => 'good      '
    expect! metal.ask("SELECT 'too long'::varchar(5)") => 'too l'
    expect! metal.ask("SELECT 'ä'") => 'ä'
  end
  
  def test_bytea
    expect! metal.ask("SELECT '1'::bytea") => '1'
  end
  
  def test_dates
    expect! metal.ask("SELECT '1/18/1999'::date") => Date.parse("18. 1. 1999")
    expect! metal.ask("SELECT '1999-01-08 04:05:06'::timestamp") => Time.parse("1999-01-08 04:05:06")
    expect! metal.ask("SELECT TIMESTAMP '1999-01-08 04:05:06'") => Time.parse("1999-01-08 04:05:06")
    expect! metal.ask("SELECT CURRENT_TIME") => Time
    expect! metal.ask("SELECT CURRENT_TIMESTAMP") => Time
  end
  
  def test_true_and_friends
    expect! metal.ask("SELECT TRUE") => true
    expect! metal.ask("SELECT FALSE") => false
    expect! metal.ask("SELECT NULL") => nil
  end
  
  def test_empty_result
    expect! metal.ask("SELECT NULL WHERE FALSE") => nil
    expect! metal.ask("SELECT 1 WHERE FALSE") => nil
  end
  
  def test_column_names
    result = metal.exec("SELECT 1 as one, 2 as two WHERE FALSE")
    expect! result.columns == %w(one two)
    expect! result.empty?

    result = metal.exec("SELECT 1 as one, 2 as two")
    expect! result.columns == %w(one two)
    expect! result == [[ 1, 2 ]]
  end
  
  def test_hstore
    result = metal.ask("SELECT 'foo=>foo,bar=>NULL'::hstore")
    assert_equal result, foo: "foo", bar: nil

    # C = PgTypedQueries::Conversions
    #
    # assert_equal C::HStore.escape(a: 1), "'a=>1'::hstore"
    # assert_equal C::HStore.escape(foo: "foo", bar: nil), "'foo=>foo,bar=>NULL'::hstore"
  end
end

module ActiveRecord::Metal::Postgresql::Conversions::Etest
  include ActiveRecord::Metal::EtestBase
  
  def test_numeric_types
    expect! metal.ask("SELECT 1") => 1

    [ "smallint", "integer", "bigint", "decimal", "numeric", "real", "double precision" ].each do |type|
      expect! metal.ask("SELECT 1::#{type}") => 1
    end
  end
  
  def test_special_numbers
    expect! metal.ask("SELECT 'Infinity'::real") => Float::INFINITY
    expect! metal.ask("SELECT '-Infinity'::real") => -Float::INFINITY 

    # Can't test for NAN == NAN
    # expect! metal.ask("SELECT 'NaN'::real") => Float::NAN 
  end

  def test_money
    expect! metal.ask("SELECT 1234::text::money") => 1234.0
  end
  
  def test_strings
    expect! metal.ask("SELECT 'ok'")
    expect! metal.ask("SELECT 'good      '") => 'good      '
    expect! metal.ask("SELECT 'too long'::varchar(5)") => 'too l'
    expect! metal.ask("SELECT 'ä'") => 'ä'
  end
  
  def test_bytea
    expect! metal.ask("SELECT '1'::bytea") => '1'
  end
  
  def test_dates
    expect! metal.ask("SELECT '1/18/1999'::date") => Date.parse("18. 1. 1999")
    expect! metal.ask("SELECT '1999-01-08 04:05:06'::timestamp") => Time.parse("1999-01-08 04:05:06")
    expect! metal.ask("SELECT TIMESTAMP '1999-01-08 04:05:06'") => Time.parse("1999-01-08 04:05:06")
    expect! metal.ask("SELECT CURRENT_TIME") => Time
    expect! metal.ask("SELECT CURRENT_TIMESTAMP") => Time
  end
  
  def test_true_and_friends
    expect! metal.ask("SELECT TRUE") => true
    expect! metal.ask("SELECT FALSE") => false
    expect! metal.ask("SELECT NULL") => nil
  end
  
  def test_empty_result
    expect! metal.ask("SELECT NULL WHERE FALSE") => nil
    expect! metal.ask("SELECT 1 WHERE FALSE") => nil
  end
  
  def test_column_names
    result = metal.exec("SELECT 1 as one, 2 as two WHERE FALSE")
    expect! result.columns == %w(one two)
    expect! result.empty?

    result = metal.exec("SELECT 1 as one, 2 as two")
    expect! result.columns == %w(one two)
    expect! result == [[ 1, 2 ]]
  end
  
  def test_hstore
    result = metal.ask("SELECT 'foo=>foo,bar=>NULL'::hstore")
    assert_equal result, foo: "foo", bar: nil

    # C = PgTypedQueries::Conversions
    #
    # assert_equal C::HStore.escape(a: 1), "'a=>1'::hstore"
    # assert_equal C::HStore.escape(foo: "foo", bar: nil), "'foo=>foo,bar=>NULL'::hstore"
  end
end
