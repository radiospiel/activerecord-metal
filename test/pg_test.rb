#!/usr/bin/env ruby
require_relative "test_helper"

Dir.glob(File.dirname(__FILE__) + "/../lib/active_record/metal/**/etest.rb").each do |file|
  load file
end

class PostgresTest < Test::Unit::TestCase
  include ActiveRecord::Metal::Etest
  include ActiveRecord::Metal::Transaction::Etest
  include ActiveRecord::Metal::Postgresql::Etest
  include ActiveRecord::Metal::Postgresql::Import::Etest
  include ActiveRecord::Metal::Postgresql::Conversions::Etest
  include ActiveRecord::Metal::Postgresql::Queries::Etest
  include ActiveRecord::Metal::Postgresql::Exec::Etest
  include ActiveRecord::Metal::Postgresql::PreparedQueries::Etest
  include ActiveRecord::Metal::Postgresql::Aggregate::Etest
end
