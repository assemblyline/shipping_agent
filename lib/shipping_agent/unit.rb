module ShippingAgent
  class Unit

    def initialize(name:, image:, env:, process:, bind: nil)
      @name = name
      @image = image
      @process = process
      @env = env
      @bind = bind
    end

    attr_reader :name

    def to_hash
      {
        'Unit' => unit,
        'Service' => service,
        'Install' => { 'WantedBy' => 'multi-user.target' },
        'X-Fleet' => x_fleet,
      }
    end

    private

    attr_reader :image, :env, :process


    def unit
      {
        'Description' => name,
        'After' => 'docker.service',
        'Requires' => 'docker.service',
      }.merge(bind)
    end

    def bind
      if bind?
        {
          'After'   => bind_service,
          'BindsTo' => bind_service,
        }
      else
        {}
      end
    end

    def bind_service
      "#{@bind.name}@%i.service"
    end

    def bind?
      !@bind.nil?
    end

    def service
      {
        'ExecStartPre' => [
          '/usr/bin/docker run --rm -v /opt/bin:/opt/bin ibuildthecloud/systemd-docker',
          "/usr/bin/docker pull #{image}",
        ],
        'ExecStart' => "/opt/bin/systemd-docker run #{port}--rm --name #{name}-%i #{formatted_env} #{image} #{process.command}", # rubocop:disable Metrics/LineLength
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

    def x_fleet
      return { 'MachineOf' => bind_service } if bind?
      { 'Conflicts' => "#{name}@*.service" }
    end

    def formatted_env
      env.reject { |_, v| v.nil? }.map { |k, v| "-e #{k}=#{v}" }.join(' ')
    end

    def port
      "-p #{process.port} " if process.exposes_port?
    end
  end
end
