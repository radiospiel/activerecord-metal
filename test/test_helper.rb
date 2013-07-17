$:.unshift File.expand_path("../../lib", __FILE__)

require "bundler"
Bundler.setup(:test)
require "simplecov"
SimpleCov.start do
  add_filter "test/*.rb"
end

require "etest-unit"
require "active_record/metal"

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :database => "activerecord_metal"
)

metal = ActiveRecord::Metal.new
metal.ask "DROP TABLE IF EXISTS test"
metal.ask "CREATE TABLE test(num INTEGER, num2 INTEGER, str1 VARCHAR)"
