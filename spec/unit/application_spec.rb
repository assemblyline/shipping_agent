require 'spec_helper'
require 'shipping_agent/application'

describe ShippingAgent::Application do
  subject { described_class.new(name: 'awesome', repo: 'quay.io/assemblyline/awesome') }

  it 'has a name' do
    expect(subject.name).to eq 'awesome'
  end

  it 'has a repo' do
    expect(subject.repo).to eq 'quay.io/assemblyline/awesome'
  end
end
