# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'graffiti_drone/version'

Gem::Specification.new do |spec|
  spec.name          = "graffiti_drone"
  spec.version       = GraffitiDrone::VERSION
  spec.authors       = ["Chris Butler"]
  spec.email         = ["chrizbo@hotmail.com"]
  spec.summary       = %q{Tag your favorite (legal) wall with your drone.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'argus', '~> 0.4'
  spec.add_dependency 'httparty', '~> 0.13'
  spec.add_dependency 'eventmachine', '~> 1.0'
  spec.add_dependency 'aasm', '~> 3.3'
  spec.add_dependency 'ox', '~> 2.1'
  spec.add_dependency 'rb-pid-controller', '~> 0.0.1'

  spec.add_dependency 'thor', '~> 0.19'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
