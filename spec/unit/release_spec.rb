require 'spec_helper'
require 'shipping_agent/application'
require 'shipping_agent/release'
require 'shipping_agent/build'

describe ShippingAgent::Release do
  let(:procfile) { 'web: bin/puma' }
  let(:application) { ShippingAgent::Application.new(name: 'awesome', repo: 'quay.io/assemblyline/awesome') }
  let(:build)       { ShippingAgent::Build.new(application: application, tag: '0.0.1', procfile: procfile) }
  let(:env) do
    {
      'FOO' => 'bar',
      'BAZ' => 'qux.com',
    }
  end

  let(:release)     { described_class.new(build: build, env: env) }

  describe 'submiting the release to fleet' do
    let(:fleet) { double(:fleet_client) }

    before do
      allow(Fleet).to receive(:new).and_return(fleet)
      allow(fleet).to receive(:submit)
    end

    it 'submits the unit to fleet' do
      expected_unit = {
        'Unit' =>         { 'Description' => 'awesome_0.0.1_e37496243_web',
                            'After' => 'docker.service',
                            'Requires' => 'docker.service' },
        'Service' =>         { 'User' => 'root',
                               'ExecStartPre' => ['/usr/bin/docker run --rm -v /opt/bin:/opt/bin ibuildthecloud/systemd-docker', # rubocop:disable Metrics/LineLength
                                                  '/usr/bin/docker pull quay.io/assemblyline/awesome:0.0.1'],
                               'ExecStart' => '/opt/bin/systemd-docker run -P --rm --name awesome_0.0.1_e37496243_web-%i -e FOO=bar -e BAZ=qux.com quay.io/assemblyline/awesome:0.0.1 bin/puma', # rubocop:disable Metrics/LineLength
                               'Restart' => 'always',
                               'RestartSec' => '10s',
                               'Type' => 'notify',
                               'NotifyAccess' => 'all',
                               'TimeoutStartSec' => '240',
                               'TimeoutStopSec' => '15' },
        'Install' => { 'WantedBy' => 'multi-user.target' },
        'X-Fleet' => { 'Conflicts' => 'awesome_0.0.1_e37496243_web@*.service' },
      }
      expect(fleet).to receive(:submit).with('awesome_0.0.1_e37496243_web@.service', expected_unit)
      release.submit
    end

    it 'submits a sidekick unit to fleet' do
      expected_sidekick = {
        'Unit' =>         { 'Description' => 'awesome_0.0.1_e37496243_web_sidekick',
                            'After' => 'docker.service',
                            'Requires' => 'docker.service' },
        'Service' =>         { 'User' => 'root',
                               'ExecStartPre' => ['/usr/bin/docker run --rm -v /opt/bin:/opt/bin ibuildthecloud/systemd-docker', # rubocop:disable Metrics/LineLength
                                                  '/usr/bin/docker pull quay.io/assemblyline/sidekicks'],
                               'ExecStart' => '/opt/bin/systemd-docker run -P --rm --name awesome_0.0.1_e37496243_web_sidekick-%i  quay.io/assemblyline/sidekicks vulcand', # rubocop:disable Metrics/LineLength
                               'Restart' => 'always',
                               'RestartSec' => '10s',
                               'Type' => 'notify',
                               'NotifyAccess' => 'all',
                               'TimeoutStartSec' => '240',
                               'TimeoutStopSec' => '15' },
        'Install' => { 'WantedBy' => 'multi-user.target' },
        'X-Fleet' => { 'Conflicts' => 'awesome_0.0.1_e37496243_web_sidekick@*.service' },
      }
      expect(fleet).to receive(:submit).with('awesome_0.0.1_e37496243_web_sidekick@.service', expected_sidekick)
      release.submit
    end

    context 'with multiple services' do
      let(:procfile) { "web: bin/puma\nworker: bin/hutch" }

      it 'submits each process' do
        web_unit = {
          'Unit' =>         { 'Description' => 'awesome_0.0.1_e37496243_web',
                              'After' => 'docker.service',
                              'Requires' => 'docker.service' },
          'Service' =>         { 'User' => 'root',
                                 'ExecStartPre' => ['/usr/bin/docker run --rm -v /opt/bin:/opt/bin ibuildthecloud/systemd-docker', # rubocop:disable Metrics/LineLength
                                                    '/usr/bin/docker pull quay.io/assemblyline/awesome:0.0.1'],
                                 'ExecStart' => '/opt/bin/systemd-docker run -P --rm --name awesome_0.0.1_e37496243_web-%i -e FOO=bar -e BAZ=qux.com quay.io/assemblyline/awesome:0.0.1 bin/puma', # rubocop:disable Metrics/LineLength
                                 'Restart' => 'always',
                                 'RestartSec' => '10s',
                                 'Type' => 'notify',
                                 'NotifyAccess' => 'all',
                                 'TimeoutStartSec' => '240',
                                 'TimeoutStopSec' => '15' },
          'Install' => { 'WantedBy' => 'multi-user.target' },
          'X-Fleet' => { 'Conflicts' => 'awesome_0.0.1_e37496243_web@*.service' },
        }

        worker_unit = {
          'Unit' =>         { 'Description' => 'awesome_0.0.1_e37496243_worker',
                              'After' => 'docker.service',
                              'Requires' => 'docker.service' },
          'Service' =>         { 'User' => 'root',
                                 'ExecStartPre' => ['/usr/bin/docker run --rm -v /opt/bin:/opt/bin ibuildthecloud/systemd-docker', # rubocop:disable Metrics/LineLength
                                                    '/usr/bin/docker pull quay.io/assemblyline/awesome:0.0.1'],
                                 'ExecStart' => '/opt/bin/systemd-docker run -P --rm --name awesome_0.0.1_e37496243_worker-%i -e FOO=bar -e BAZ=qux.com quay.io/assemblyline/awesome:0.0.1 bin/hutch', # rubocop:disable Metrics/LineLength
                                 'Restart' => 'always',
                                 'RestartSec' => '10s',
                                 'Type' => 'notify',
                                 'NotifyAccess' => 'all',
                                 'TimeoutStartSec' => '240',
                                 'TimeoutStopSec' => '15' },
          'Install' => { 'WantedBy' => 'multi-user.target' },
          'X-Fleet' => { 'Conflicts' => 'awesome_0.0.1_e37496243_worker@*.service' },
        }
        expect(fleet).to receive(:submit).with('awesome_0.0.1_e37496243_web@.service', web_unit)
        expect(fleet).to receive(:submit).with('awesome_0.0.1_e37496243_worker@.service', worker_unit)
        release.submit
      end
    end
  end

  describe 'generating a tag' do
    it 'is consistent for a given env build and application' do
      100.times do
        expect(described_class.new(build: build, env: env).tag).to eq 'e374962439fee0d7745ca77fae294a1792cec248'
      end
    end

    it 'is unique for a given env' do
      tags = 10_000.times.map do
        env = { 'UUID' => SecureRandom.uuid }
        described_class.new(build: build, env: env).tag
      end
      expect(tags.uniq.size).to eq 10_000
    end

    it 'is unique for a given application' do
      tags = 10_000.times.map do
        application = ShippingAgent::Application.new(name: SecureRandom.uuid, repo: 'quay.io/assemblyline/awesome')
        build = ShippingAgent::Build.new(application: application, tag: '0.0.1', procfile: 'web: bin/puma')
        described_class.new(build: build, env: {}).tag
      end
      expect(tags.uniq.size).to eq 10_000
    end

    it 'is unique for a given build' do
      tags = 10_000.times.map do
        application = ShippingAgent::Application.new(name: 'application', repo: 'quay.io/assemblyline/awesome')
        build = ShippingAgent::Build.new(application: application, tag: SecureRandom.uuid, procfile: 'web: bin/puma')
        described_class.new(build: build, env: {}).tag
      end
      expect(tags.uniq.size).to eq 10_000
    end
  end
end
