$:.unshift File.expand_path("../lib", __FILE__)

require "bundler/setup"

require "rake/testtask"
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end

# Add "rake release and rake install"
Bundler::GemHelper.install_tasks

task :default => :test
