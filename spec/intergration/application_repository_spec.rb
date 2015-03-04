require 'spec_helper'
require 'shipping_agent/application_repository'

describe ShippingAgent::ApplicationRepository, :etcd do
  let(:fleet) { double(:fleet_client) }

  before do
    allow(Fleet).to receive(:new).and_return(fleet)
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

    expect(fleet).to receive(:submit).once do |name, unit|
      expect(name).to eq 'todo-app_v1_e27982344_web@.service'
      expect(unit['Service']['ExecStart']).to include('bin/puma')
      expect(unit['Service']['ExecStart']).to include('-e RACK_ENV=production')
    end

    expect(fleet).to receive(:submit).once do |name, _|
      expect(name).to eq 'todo-app_v1_e27982344_web_sidekick@.service'
    end

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

    expect(fleet).to receive(:submit).once do |name, unit|
      expect(name).to eq 'todo-app_v1_124048c26_web@.service'
      expect(unit['Service']['ExecStart']).to include('bin/puma')
      expect(unit['Service']['ExecStart']).to include(
        '-e DATABASE_URL=postgres://user:pass@database.example.com/todos',
      )
    end

    expect(fleet).to receive(:submit).once do |name, _|
      expect(name).to eq 'todo-app_v1_124048c26_web_sidekick@.service'
    end

    application.release(
      build_tag: 'v1',
      env: { 'DATABASE_URL' => 'postgres://user:pass@database.example.com/todos', 'RACK_ENV' => 'production' },
    )
  end
end
