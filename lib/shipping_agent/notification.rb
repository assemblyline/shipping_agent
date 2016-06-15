require "octokit"
require "shipping_agent/logger"

module ShippingAgent
  module Notification
    extend self
    def update(status, description, deploy)
      github.create_deployment_status(
        deploy.url,
        status,
        accept: "application/vnd.github.ant-man-preview+json",
        description: description,
      )
    rescue => e
      LOGGER.warn do
        "Failed to update github with: [#{status}] #{description} - due to: #{e.class} #{e.message}"
      end
    end

    private

    def github
      @github_client ||= Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN"))
    end
  end
end
