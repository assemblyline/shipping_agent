require 'spec_helper'
require 'shipping_agent/application'
require 'shipping_agent/build'

describe ShippingAgent::Build do
  let(:application) { ShippingAgent::Application.new(name: 'awesome', repo: 'quay.io/assemblyline/awesome') }
  subject { described_class.new(application: application, tag: '0.0.1') }

  it 'has an image' do
    expect(subject.image).to eq 'quay.io/assemblyline/awesome:0.0.1'
  end
end
