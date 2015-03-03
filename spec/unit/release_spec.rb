require 'spec_helper'
require 'shipping_agent/application'
require 'shipping_agent/release'
require 'shipping_agent/build'

describe ShippingAgent::Release do
  let(:application) { ShippingAgent::Application.new(name: 'awesome', repo: 'quay.io/assemblyline/awesome') }
  let(:build)       { ShippingAgent::Build.new(application: application, tag: '0.0.1', procfile: 'web: bin/puma') }
  let(:env) do
    {
      'FOO' => 'bar',
      'BAZ' => 'qux.com',
    }
  end

  let(:release)     { described_class.new(build: build, env: env) }

  it 'can create its unit config' do
    expect(release.to_unit('web')).to eq(
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
      'X-Fleet' => { 'Conflicts' => 'awesome_0.0.1_e37496243_web@*.service' })
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
