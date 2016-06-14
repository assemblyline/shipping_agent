require "shipping_agent/k8s"

module ShippingAgent
  class Deploy
    def initialize(info)
      @app       = info[:app].tr("_", "-")
      @image     = info[:image]
      @labels  = info[:labels]
      @namespace = info[:namespace]
    end

    attr_reader :app, :image, :labels, :namespace

    def self.deploy(info)
      new(info).apply
    end

    def apply
      deployments.each do |deployment|
        K8s.patch_deployment(
          name: deployment,
          namespace: namespace,
          body: {
            "metadata" => { "labels" => labels },
            "spec" => {
              "template" => {
                "metadata" => { "labels" => labels },
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

    def deployments
      K8s.deployments(namespace: namespace, selector: { app: app }).map { |deployment| deployment["metadata"]["name"] }
    end
  end
end
