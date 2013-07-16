#!/usr/bin/env ruby
require_relative "test_helper"
require "active_record/metal/postgresql"

class PostgresTest < Test::Unit::TestCase
  include ActiveRecord::Metal::Postgresql::Etest
  
  def test_ok
    assert(true)
  end
end
