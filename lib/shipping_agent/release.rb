module ShippingAgent
  class Release
    def initialize(build:, env:)
      self.build = build
      self.env     = env
    end

    def to_unit
      {
        'Unit' => unit,
        'Service' => service,
        'Install' => { 'WantedBy' => 'multi-user.target' },
        'X-Fleet' => { 'Conflicts' => "#{name}@*.service" },
      }
    end

    protected

    attr_accessor :build, :env

    private

    def unit
      {
        'Description' => name,
        'After' => 'docker.service',
        'Requires' => 'docker.service',
      }
    end

    def service
      {
        'ExecStartPre' => [
          '/usr/bin/docker run --rm -v /opt/bin:/opt/bin ibuildthecloud/systemd-docker',
          "/usr/bin/docker pull #{image}",
        ],
        'ExecStart' => "/opt/bin/systemd-docker run -P --rm --name #{name}-%i #{formated_env} #{image}",
      }.merge(service_defaults)
    end

    def service_defaults
      {
        'User' => 'root',
        'Restart' => 'always',
        'RestartSec' => '10s',
        'Type' => 'notify',
        'NotifyAccess' => 'all',
        'TimeoutStartSec' => '240',
        'TimeoutStopSec' => '15',
      }
    end

    def formated_env
      env.map { |k, v| "-e #{k}=#{v}" }.join(' ')
    end

    def image
      build.image
    end

    def name
      build.application.name
    end
  end
end
