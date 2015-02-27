module ShippingAgent
  class Release
    def initialize(build:, env:)
      self.build = build
      self.env     = env
    end

    def to_unit
      {
        "Unit" => {
        "Description" => name,
        "After" => "docker.service",
        "Requires" => "docker.service",
      },
      "Service" => {
        "User" => "root",
        "ExecStartPre" => [
          "/usr/bin/docker run --rm -v /opt/bin:/opt/bin ibuildthecloud/systemd-docker",
          "/usr/bin/docker pull #{image}",
        ],
        "ExecStart" => "/opt/bin/systemd-docker run -P --rm --name #{name}-%i #{formated_env} #{image}",
        "Restart" => "always",
        "RestartSec" => "10s",
        "Type" => "notify",
        "NotifyAccess" => "all",
        "TimeoutStartSec" => "240",
        "TimeoutStopSec" => "15",
      },
      "Install" => {
        "WantedBy" => "multi-user.target",
      },
      "X-Fleet" => {
        "Conflicts" => "#{name}@*.service",
      }
      }
    end

    protected

    attr_accessor :build, :env

    private
    def formated_env
      env.map { |k,v| "-e #{k}=#{v}" }.join(" ")
    end

    def image
      build.image
    end

    def name
      build.application.name
    end
  end
end
