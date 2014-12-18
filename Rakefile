########################################
# Testing

require 'rspec/core/rake_task'
require 'mutant'

RSpec::Core::RakeTask.new

task :default => :mutant

task :mutant do
  pattern = ENV.fetch('PATTERN', 'Typecheck*')
  opts    = ENV.fetch('MUTANT_OPTS', '').split(' ')
  result  = Mutant::CLI.run(%w[-Ilib -rtypecheck --use rspec --score 100] + opts + [pattern])
  fail unless result == Mutant::CLI::EXIT_SUCCESS
end

########################################
# Packaging

require 'rubygems/package_task'
spec = Gem::Specification.load(File.expand_path('../typecheck.gemspec', __FILE__))
gem = Gem::PackageTask.new(spec)
gem.define

desc "Push gem to rubygems.org"
task :push => :gem do
  sh "git tag v#{Typecheck::VERSION}"
  sh "git push --tags"
  sh "gem push pkg/typecheck-#{Typecheck::VERSION}.gem"
end
