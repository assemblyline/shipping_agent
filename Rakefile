require "reevoocop/rake_task"
require "rspec/core/rake_task"
require "bundler/audit/task"

Bundler::Audit::Task.new
ReevooCop::RakeTask.new(:reevoocop)
RSpec::Core::RakeTask.new(:spec)
task default: [:spec, :reevoocop, "bundle:audit"]
