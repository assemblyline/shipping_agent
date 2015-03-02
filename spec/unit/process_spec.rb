require 'spec_helper'
require 'shipping_agent/process'

describe ShippingAgent::Process do
  subject { described_class.new(name: 'foo', command: 'bundle exec rake foo') }

  it 'has a name and command' do
    expect(subject.name).to eq 'foo'
    expect(subject.command).to eq 'bundle exec rake foo'
  end
end
