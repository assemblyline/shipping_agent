require "shipping_agent/k8s"
require "shipping_agent/notification"

module ShippingAgent
  class Deploy
    def initialize(info)
      @app       = info[:app].tr("_", "-")
      @image     = info[:image]
      @labels    = info[:labels]
      @namespace = info[:namespace]
      @url       = info[:deployment_url]
    end

    attr_reader :app, :image, :labels, :namespace, :url

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
        Notification.update("pending", "Config for #{deployment} pushed to kubernetes", url)
      end
      Thread.new { wait }
    end

    def wait
      Timeout.timeout(300) do
        loop do
          if deployments.all? { |name| update_complete?(name) }
            Notification.update("success", "#{app} deployed sucessfully to #{namespace}", self)
            break
          end
          sleep 0.5
        end
      end
    rescue Timeout::Error
      Notification.update("error", "#{app} deploy to #{namespace} timed out", self)
    end

    private

    def update_complete?(name)
      K8s.deployment(namespace: namespace, name: name)["status"]
        .values_at("replicas", "updatedReplicas", "availableReplicas")
        .uniq.size == 1
    end

    def deployments
      @deployments ||= K8s.deployments(
        namespace: namespace,
        selector: { app: app },
      ).map { |deployment| deployment["metadata"]["name"] }
    end
  end
end
