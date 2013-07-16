#!/usr/bin/env ruby
require_relative "test_helper"
require "active_record/metal/postgresql"
require "active_record/metal/postgresql/etest"

class PostgresTest < Test::Unit::TestCase
  include ActiveRecord::Metal::Postgresql::Etest
  
  def test_ok
    assert(true)
  end
end
