$:.unshift File.expand_path("../lib", __FILE__)
require "active_record/metal/version"

class Gem::Specification
  class GemfileEvaluator
    def initialize(scope)
      @scope = scope
    end
    
    def load_dependencies(path)
      instance_eval File.read(path) 
    end
    
    def source(*args); end
    def group(*args); end

    def gem(name, options = {})
      @scope.add_dependency(name)
    end
  end
  
  def load_dependencies(file)
    GemfileEvaluator.new(self).load_dependencies(file)
  end
end

Gem::Specification.new do |gem|
  gem.name     = "activerecord-metal"
  gem.version  = ActiveRecord::Metal::VERSION

  gem.author   = "radiospiel"
  gem.email    = "eno@radiospiel.org"
  gem.homepage = "http://github.com/radiospiel/etest"
  gem.summary  = "Build your tests alongside your code."

  gem.description = gem.summary
  gem.load_dependencies "Gemfile"

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }
end
