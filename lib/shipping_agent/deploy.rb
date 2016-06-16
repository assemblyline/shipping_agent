require "shipping_agent/k8s"
require "shipping_agent/notification"
require "shipping_agent/worker"

module ShippingAgent
  class Deploy
    def initialize(info)
      @app          = info[:app].tr("_", "-")
      @image        = info[:image]
      @labels       = info[:labels]
      @namespace    = info[:namespace]
      @url          = info[:deployment_url]
      @poll_speed   = info[:poll_speed] || 0.5
      @creator      = info[:creator]
      @description  = info[:description]
    end

    attr_reader :app, :image, :labels, :namespace, :url, :creator, :description

    def self.deploy(info)
      new(info).apply
    end

    def apply
      Notification.update("request", "Deployment of `#{app}` to `#{namespace}` was requested", self)
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
        Notification.update("pending", "Config for #{deployment} pushed to kubernetes", self)
      end
      Worker.work(-> { notify_when_complete })
    end

    def notify_when_complete
      check_until = Time.now + ENV.fetch("DEPLOY_TIMEOUT", "300").to_i
      until Time.now >= check_until
        if complete?
          Notification.update("success", "#{app} deployed sucessfully to #{namespace}", self)
          return
        end
        sleep @poll_speed
      end
      Notification.update("error", "#{app} deploy to #{namespace} timed out", self)
    end

    private

    def complete?
      deployments.all? { |name| update_complete?(name) }
    end

    def deployments
      @deployments ||= K8s.deployments(
        namespace: namespace,
        selector: { app: app },
      ).map { |deployment| deployment["metadata"]["name"] }
    end

    def update_complete?(name)
      K8s.deployment(namespace: namespace, name: name)["status"]
        .values_at("replicas", "updatedReplicas", "availableReplicas")
        .uniq.size == 1
    end
  end
end
