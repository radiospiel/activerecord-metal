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
end
