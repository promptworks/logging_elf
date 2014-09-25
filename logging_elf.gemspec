# rubocop:disable RegexpLiteral
# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logging_elf/version'

Gem::Specification.new do |spec|
  spec.name          = 'logging_elf'
  spec.version       = LoggingElf::VERSION
  spec.authors       = ['Jeff Deville']
  spec.email         = ['jeffdeville@gmail.com']
  spec.summary       = 'Logging, Tracing, and Gelf Logging for rails'
  spec.description   = 'Logging, Tracing, and Gelf Logging for rails'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'logging', '~> 1.8'
  spec.add_dependency 'virtus', '~> 1.0'
  spec.add_dependency 'activemodel'
  spec.add_dependency 'gelf'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.0'
  spec.add_development_dependency 'rubocop', '~> 0.25'
end
