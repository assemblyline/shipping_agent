require "simplecov"

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.minimum_coverage 99
SimpleCov.minimum_coverage_by_file 95
SimpleCov.start

require "pry"
require "webmock/rspec"

ENV["RACK_ENV"] ||= "test"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

def with_env(env)
  old_env = {}
  env.each do |k, v|
    old_env[k] = ENV[k]
    ENV[k] = v
  end
  yield
  old_env.each do |k, v|
    ENV[k] = v
  end
end
