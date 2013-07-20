module ActiveRecord::Metal::Postgresql::Exec
  private

  # -- raw queries ----------------------------------------------------

  def exec_(sql)
    pg_conn.exec(sql)
  end

  def exec_prepared(sym, *args)
    args = args.map do |arg|
      if arg.is_a?(Hash)
        ActiveRecord::Metal::Postgresql::Conversions::HStore.escape(arg)
      else
        arg
      end
    end

    pg_conn.exec_prepared(sym.to_s, args)
  end
end

module ActiveRecord::Metal::Postgresql::Exec::Etest
  include ActiveRecord::Metal::EtestBase

  def test_error_on_prepare
    assert_raise(PG::Error) {  
      metal.prepare "SELECT unknown_function(1)"
    }
  end

  def test_error_on_exec
    assert_raise(PG::Error) {  
      metal.ask "SELECT unknown_function(1)"
    }
  end

  def test_error_on_unprepare
    assert_raise(PG::Error) {  
      metal.unprepare "SELECT unknown_function(1)"
    }
  end

  def test_error_on_exec_with_args
    assert_raise(PG::Error) {  
      metal.ask "SELECT num FROM alloys WHERE unknown_function(id) > $1", 1
    }
  end
end
