module ActiveRecord::Metal::Postgresql::Aggregate
  def count(table_name)
    ask "SELECT COUNT(*) FROM #{table_name}"
  end
end

module ActiveRecord::Metal::Postgresql::Aggregate::Etest
  def test_count
    metal.ask "DELETE FROM alloys"
    expect! metal.count("alloys") => 0
    metal.import "alloys", [[1,1], [2,2]], :columns => [ "id", "num"]
    expect! metal.count("alloys") => 2
    metal.ask "DELETE FROM alloys"
  end
end
