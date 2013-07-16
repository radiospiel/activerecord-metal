$:.unshift File.expand_path("../../lib", __FILE__)

require "bundler"
Bundler.require(:test)

require "active_record/metal"
require "etest-unit"

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :database => "activerecord_metal"
)

metal = ActiveRecord::Metal.new
metal.ask "DROP TABLE IF EXISTS test"
metal.ask "CREATE TABLE test(num INTEGER)"
