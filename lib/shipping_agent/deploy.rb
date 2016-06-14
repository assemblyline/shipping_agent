require "shipping_agent/k8s"

module ShippingAgent
  class Deploy
    def initialize(info)
      @app       = info[:app].tr("_", "-")
      @build     = info[:build]
      @deploy    = info[:deploy]
      @image     = info[:image]
      @namespace = info[:namespace]
      @version   = info[:version]
    end

    attr_reader :app, :build, :deploy, :image, :namespace, :version

    def self.deploy(info)
      new(info).apply
    end

    def apply
      deployments.each do |deployment|
        K8s.patch_deployment(
          name: deployment,
          namespace: namespace,
          body: {
            "metadata" => metadata,
            "spec" => {
              "template" => {
                "metadata" => metadata,
                "spec" => {
                  "containers" => [
                    {
                      "name" => app,
                      "image" => image,
                    },
                  ],
                },
              },
            },
          },
        )
      end
    end

    private

    def metadata
      {
        "labels" => {
          "version" => version,
          "build"   => build,
          "deploy"  => deploy,
        },
      }
    end

    def deployments
      K8s.deployments(namespace: namespace, selector: { app: app }).map { |deployment| deployment["metadata"]["name"] }
    end
  end
end
