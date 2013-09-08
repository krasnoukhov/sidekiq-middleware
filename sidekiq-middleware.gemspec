# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sidekiq-middleware/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dmitry Krasnoukhov"]
  gem.email         = ["dmitry@krasnoukhov.com"]
  gem.description   = gem.summary = "Additional sidekiq middleware"
  gem.homepage      = "http://github.com/krasnoukhov/sidekiq-middleware"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sidekiq-middleware"
  gem.require_paths = ["lib"]
  gem.version       = Sidekiq::Middleware::VERSION

  gem.add_dependency                  'sidekiq',  '>= 2.12.4', '< 3'
  gem.add_development_dependency      'rake'
  gem.add_development_dependency      'bundler',  '~> 1.0'
  gem.add_development_dependency      'minitest', '~> 3'
  gem.add_development_dependency      'timecop'
end
