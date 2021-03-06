# encoding: utf-8

require File.expand_path('../lib/typecheck', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'typecheck'
  gem.version     = Typecheck::VERSION
  gem.authors     = [ 'Arne Brasseur' ]
  gem.email       = [ 'arne@arnebrasseur.net' ]
  gem.description = 'Type checking for Ruby methods.'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/plexus/typecheck'
  gem.license     = 'MIT'

  gem.require_paths    = %w[lib]
  gem.files            = `git ls-files`.split($/)
  gem.test_files       = `git ls-files -- spec`.split($/)
  gem.extra_rdoc_files = %w[README.md LICENSE]

  gem.add_development_dependency 'rake'         , '~> 10.4'
  gem.add_development_dependency 'rspec'        , '~> 3'
  gem.add_development_dependency 'mutant-rspec' , '~> 0'
end
