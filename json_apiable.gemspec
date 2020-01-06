lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "json_apiable/version"

Gem::Specification.new do |spec|
  spec.name          = "json_apiable"
  spec.version       = JsonApiable::VERSION
  spec.authors       = ["Mike Polischuk"]
  spec.email         = ["mike.polis@gmail.com"]

  spec.summary       = %q{Include JsonApiable module in your API::BaseController to receive a collection of useful
                          methods, such as arguments and relationships parser, filters, etc.}
  spec.homepage      = "http://github.com/mikemarsian/json_apiable"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', '>= 4.2'
  spec.add_dependency 'activesupport', '>= 4.2'
  spec.add_dependency 'fast_jsonapi', '~> 1.5'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rails-controller-testing'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'sqlite3'
end
