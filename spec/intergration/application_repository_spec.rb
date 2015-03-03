require 'spec_helper'
require 'shipping_agent/application_repository'

describe ShippingAgent::ApplicationRepository do
  before do
    described_class.etcd.delete('/assemblyline/', recursive: true)
  end

  it 'works as expected' do
    application = ShippingAgent::ApplicationRepository.get('todo-app')
    expect(application).to be_nil

    application = ShippingAgent::Application.new(name: 'todo-app', repo: 'quay.io/reevoo/todo-app')
    ShippingAgent::ApplicationRepository.save(application)
    application = ShippingAgent::ApplicationRepository.get('todo-app')
    expect(application.name).to eq 'todo-app'
    expect(application.repo).to eq 'quay.io/reevoo/todo-app'
    expect(application.builds).to eq []
    expect(application.releases).to eq []

    application.register_build(
      tag: 'v1',
      procfile: 'web: bin/puma',
    )
    ShippingAgent::ApplicationRepository.save(application)

    application = ShippingAgent::ApplicationRepository.get('todo-app')
    expect(application.builds.size).to eq 1
    build = application.builds.first
    expect(build.application).to eq application
    expect(build.tag).to eq 'v1'
    expect(build.processes.first.name).to eq 'web'
    expect(build.processes.first.command).to eq 'bin/puma'
    expect(application.releases).to eq []

    application.release(build_tag: 'v1', env: { 'RACK_ENV' => 'production' })
    release_tag = application.releases.first.tag
    ShippingAgent::ApplicationRepository.save(application)

    application = ShippingAgent::ApplicationRepository.get('todo-app')
    expect(application.builds.size).to eq 1
    expect(application.releases.size).to eq 1
    release = application.releases.first
    expect(release.tag).to eq release_tag
    expect(release.build.tag).to eq build.tag
    expect(release.env).to eq('RACK_ENV' => 'production')

    application.release(build_tag: 'v1', env: { 'RACK_ENV' => 'production' })
  end
end
