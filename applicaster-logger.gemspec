# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'applicaster/logger/version'

Gem::Specification.new do |spec|
  spec.name          = "applicaster-logger"
  spec.version       = Applicaster::Logger::VERSION
  spec.authors       = ["Vitaly Gorodetsky"]
  spec.email         = ["v.gorodetsky@applicaster.com"]
  spec.description   = %q{ Applicaster Logger configurator }
  spec.summary       = %q{ Configures loggers to send logs to logstash }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'logstash-logger', '~> 0.25'
  spec.add_dependency 'lograge'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
