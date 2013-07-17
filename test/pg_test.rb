#!/usr/bin/env ruby
require_relative "test_helper"
require "active_record/metal/postgresql"
require "active_record/metal/postgresql/etest"
require "active_record/metal/postgresql/conversions/etest"

class PostgresTest < Test::Unit::TestCase
  include ActiveRecord::Metal::Etest
  include ActiveRecord::Metal::EtestBase
  include ActiveRecord::Metal::Transaction::Etest
  include ActiveRecord::Metal::Postgresql::Import::Etest
  include ActiveRecord::Metal::Postgresql::Conversions::Etest
end
