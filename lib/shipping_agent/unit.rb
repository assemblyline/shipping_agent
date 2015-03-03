module ShippingAgent
  class Unit

    def initialize(name:, image:, env:, process:)
      @name = name
      @image = image
      @process = process
      @env = env
    end

    attr_reader :name

    def to_hash
      {
        'Unit' => unit,
        'Service' => service,
        'Install' => { 'WantedBy' => 'multi-user.target' },
        'X-Fleet' => { 'Conflicts' => "#{name}@*.service" },
      }
    end

    private

    attr_reader :image, :env, :process


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
        'ExecStart' => "/opt/bin/systemd-docker run -P --rm --name #{name}-%i #{formated_env} #{image} #{process.command}", # rubocop:disable Metrics/LineLength
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
  end
end
