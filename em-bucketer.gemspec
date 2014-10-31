# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'em-bucketer/version'

Gem::Specification.new do |spec|
  spec.name          = "em-bucketer"
  spec.version       = EventMachine::Bucketer::VERSION
  spec.authors       = ["Richard Heycock", "Dylan Griffith"]
  spec.email         = ["dyl.griffith@gmail.com"]
  spec.summary       = %q{A generic eventmachine library for storing arbitrary objects in buckets with callbacks on threshold reached}
  spec.homepage      = "https://github.com/dgvz/em-bucketer"
  spec.license       = "GPL"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency     "eventmachine"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
