# -*- encoding: utf-8 -*-
require File.expand_path('../lib/captain-druberspace/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Oliver Grimm"]
  gem.email         = ["olly@pixelpogo.de"]
  gem.description   = %q{Lightweight and fast Drupal deployment on uberspace.de}
  gem.summary       = %q{Lightweight and fast Drupal deployment on uberspace.de}
  gem.homepage      = "https://github.com/pixelpogo/captain-druberspace"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "captain-druberspace"
  gem.require_paths = ["lib"]
  gem.version       = Captain::Druberspace::VERSION

  gem.add_runtime_dependency "capistrano"
  gem.add_runtime_dependency "railsless-deploy"


end
