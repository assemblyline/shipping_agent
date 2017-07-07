# frozen_string_literal: true
require "spec_helper"
require "rack/test"

ENV["RACK_ENV"] ||= "test"

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end
