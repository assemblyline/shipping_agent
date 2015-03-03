require 'spec_helper'
require 'shipping_agent/application'
require 'shipping_agent/build'

describe ShippingAgent::Build do
  let(:application) { ShippingAgent::Application.new(name: 'awesome', repo: 'quay.io/assemblyline/awesome') }
  let(:procfile) { "web: bin/puma\nbackend: bin/backend -c config/foo.yml" }
  subject { described_class.new(application: application, tag: '0.0.1', procfile: procfile) }

  it 'has an image' do
    expect(subject.image).to eq 'quay.io/assemblyline/awesome:0.0.1'
  end

  it 'has processes' do
    expect(subject.processes.first.name).to eq 'web'
    expect(subject.processes.first.command).to eq 'bin/puma'
    expect(subject.processes.last.name).to eq 'backend'
    expect(subject.processes.last.command).to eq 'bin/backend -c config/foo.yml'
  end

  it 'has the raw procfile content' do
    expect(subject.procfile).to eq procfile
  end
end
