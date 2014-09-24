$:.unshift File.expand_path("../../lib", __FILE__)

require "bundler"
Bundler.setup(:test)
require "simplecov"
SimpleCov.start

require "etest-unit"
require "active_record/metal"

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :database => "activerecord_metal"
)

metal = begin
  ActiveRecord::Metal.new
rescue ActiveRecord::NoDatabaseError
  STDERR.puts "[ERR] Make sure there is a database 'activerecord_metal' on the current postgresql connection."
  exit 0
end

metal.ask "DROP TABLE IF EXISTS alloys"
metal.ask <<-SQL
CREATE TABLE alloys(
  id SERIAL PRIMARY KEY, 
  num INTEGER, 
  num2 INTEGER, 
  str1 VARCHAR, 
  hsh hstore
)
SQL

class Alloy < ActiveRecord::Base
end

require "logger"

ENV["ARM_ENV"] = "test"

# ActiveRecord::Base.logger = Logger.new File.open(File.expand_path("../../log/test.log", __FILE__), "w")
ActiveRecord::Base.logger = Logger.new STDERR
ActiveRecord::Base.logger.level = Logger::INFO
