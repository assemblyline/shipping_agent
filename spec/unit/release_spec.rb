require 'spec_helper'
require 'shipping_agent/application'
require 'shipping_agent/release'
require 'shipping_agent/build'

describe ShippingAgent::Release do
  let(:application) { ShippingAgent::Application.new(name: 'awesome', repo: 'quay.io/assemblyline/awesome') }
  let(:build)       { ShippingAgent::Build.new(application: application, tag: '0.0.1') }
  let(:env) do
    {
      'FOO' => 'bar',
      'BAZ' => 'qux.com'
    }
  end

  let(:release)     { described_class.new(build: build, env: env) }

  it 'can create its unit config' do
    expect(release.to_unit).to eq(
      {"Unit"=>
        {"Description"=>"awesome",
          "After"=>"docker.service",
          "Requires"=>"docker.service"},
          "Service"=>
        {"User"=>"root",
          "ExecStartPre"=> ["/usr/bin/docker run --rm -v /opt/bin:/opt/bin ibuildthecloud/systemd-docker",
                            "/usr/bin/docker pull quay.io/assemblyline/awesome:0.0.1"],
          "ExecStart"=> "/opt/bin/systemd-docker run -P --rm --name awesome-%i -e FOO=bar -e BAZ=qux.com quay.io/assemblyline/awesome:0.0.1",
          "Restart"=>"always",
          "RestartSec"=>"10s",
          "Type"=>"notify",
          "NotifyAccess"=>"all",
          "TimeoutStartSec"=>"240",
          "TimeoutStopSec"=>"15"},
          "Install"=>{"WantedBy"=>"multi-user.target"},
          "X-Fleet"=>{"Conflicts"=>"awesome@*.service"}})
  end
end
