$:.unshift File.expand_path("../../lib", __FILE__)

require "bundler"
Bundler.setup(:test)

require "active_record/metal"
require "etest-unit"
