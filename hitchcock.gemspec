# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hitchcock/version'

Gem::Specification.new do |spec|
  spec.name          = "hitchcock"
  spec.version       = Hitchcock::VERSION
  spec.authors       = ["Felix Roeser"]
  spec.email         = ["fr@xilef.me"]
  spec.description   = %q{}
  spec.summary       = %q{}
  spec.homepage      = "https://github.com/felixroeser/42195-hitchcock"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "trollop", "~> 2.0"
  spec.add_dependency "zk"
  spec.add_dependency "marathon_client"
  spec.add_dependency "logging"
  spec.add_dependency "awesome_print"

  spec.add_development_dependency "bundler"
end
