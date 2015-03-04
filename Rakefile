require 'reevoocop/rake_task'
require 'rspec/core/rake_task'

ReevooCop::RakeTask.new(:reevoocop) do |task|
  task.patterns = ['lib/**/*.rb', 'spec/**/*.rb', 'Gemfile', 'Rakefile']
end

RSpec::Core::RakeTask.new(:spec)

task default: [:spec, :reevoocop]
