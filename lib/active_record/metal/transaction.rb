module ActiveRecord::Metal::Transaction
  # We use ActiveRecord::Base's transaction, because this one supports
  # nested transactions by automatically falling back to savepoints
  # when needed.
  def transaction(mode = :readwrite, &block)
    if mode == :readonly
      ro_transaction(&block)
    else
      connection.transaction(&block)
    end
  end
  
  private
  
  def ro_transaction(&block)
    r = nil
    connection.transaction do 
      r = yield
      raise ActiveRecord::Rollback
    end
    r
  end
end

module ActiveRecord::Metal::Transaction::Etest
  def test_transaction_return_values
    expect! metal.transaction { 1 } => 1
    expect! metal.transaction(:readonly) { 1 } => 1
  end
  
  def test_transaction
    expect! metal.ask("SELECT COUNT(*) FROM test") => 0
    metal.transaction { metal.ask "INSERT INTO test(num) VALUES(1)" }
    expect! metal.ask("SELECT COUNT(*) FROM test") => 1
  end
  
  def test_ro_transaction
    expect! metal.ask("SELECT COUNT(*) FROM test") => 0
    metal.transaction(:readonly) { metal.ask "INSERT INTO test(num) VALUES(1)" }
    expect! metal.ask("SELECT COUNT(*) FROM test") => 0
  end
end
