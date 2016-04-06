# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'restroom/version'

Gem::Specification.new do |spec|
  spec.name          = "restroom"
  spec.version       = Restroom::VERSION
  spec.authors       = ["Simon Hildebrandt"]
  spec.email         = ["simon.hildebrandt@fairfaxmedia.com.au"]

  spec.summary       = %q{RESTful api gem scaffolding}
  spec.description   = %q{Restroom provides an expressive DSL for quickly implementing wrapper gems for REST APIs.}
  spec.homepage      = "http://github.com/fairfaxmedia/restroom"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'json'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency 'faraday_middleware'
end
