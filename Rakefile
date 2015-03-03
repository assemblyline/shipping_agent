require 'reevoocop/rake_task'
require 'rspec/core/rake_task'

ReevooCop::RakeTask.new(:reevoocop)
RSpec::Core::RakeTask.new(:spec)

task default: [:spec, :reevoocop]
