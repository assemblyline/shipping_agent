require 'reevoocop/rake_task'
require 'rspec/core/rake_task'

ReevooCop::RakeTask.new(:reevoocop) do |task|
  task.patterns = ['lib/**/*.rb', 'spec/**/*.rb', 'Gemfile', 'Rakefile']
end

RSpec::Core::RakeTask.new(:spec)

task spec: [:etcd]

task default: [:spec, :reevoocop]

task :etcd do
  pid = fork do
    exec "spec/bin/#{platform}/etcd"
  end

  sleep 2

  at_exit do
    Process.kill('TERM', pid)
    Process.wait
    `rm -rf default.etcd`
  end
end

def platform
  `uname`.strip.downcase
end
