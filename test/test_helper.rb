$:.unshift File.expand_path("../../lib", __FILE__)

require "bundler"
Bundler.setup(:test)
require "simplecov"

require "etest-unit"
require "active_record/metal"

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :database => "activerecord_metal"
)

metal = ActiveRecord::Metal.new
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

# ActiveRecord::Base.logger = Logger.new File.open(File.expand_path("../../log/test.log", __FILE__), "w")
ActiveRecord::Base.logger = Logger.new STDERR
ActiveRecord::Base.logger.level = Logger::INFO
# ActiveRecord::Base.auto_explain_threshold_in_seconds = 0.010