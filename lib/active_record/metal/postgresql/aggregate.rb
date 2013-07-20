module ActiveRecord::Metal::Postgresql::Aggregate
  def count(table_name)
    ask "SELECT COUNT(*) FROM #{table_name}"
  end
end
