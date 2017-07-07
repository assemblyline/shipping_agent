# frozen_string_literal: true
require "octokit"
require "shipping_agent/logger"
require "shipping_agent/notification"

module ShippingAgent
  module Github
    class Notification
      SUPPORTED_STATUSES = %w(pending success error inactive).freeze

      def update(status, description, deploy)
        return unless SUPPORTED_STATUSES.include?(status)
        github.create_deployment_status(
          deploy.url,
          status,
          accept: "application/vnd.github.ant-man-preview+json",
          description: description,
        )
        mark_old_deployments_inactive(deploy) if status == "success"
      rescue => e
        LOGGER.warn do
          "Failed to update github with: [#{status}] #{description} - due to: #{e.class} #{e.message}"
        end
      end

      private

      # Github has an option to do this automaticly, but it only works
      # for non-production environments.
      def mark_old_deployments_inactive(deploy)
        active_old_deployments(deploy).each { |deployment| mark_inactive(deployment) }
      end

      def active_old_deployments(current)
        old_deployments(current).reject do |deployment|
          current.url == deployment.url ||
            deployment.rels[:statuses].get.data.any? { |s| s.state == "inactive" }
        end
      end

      def old_deployments(deploy)
        github.get(
          github.get(deploy.url).rels[:repository].get.data.deployments_url,
          environment: deploy.namespace,
        )
      end

      def mark_inactive(deployment)
        github.create_deployment_status(
          deployment.url,
          "inactive",
          accept: "application/vnd.github.ant-man-preview+json",
        )
      end

      def github
        @github_client ||= Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN"))
      end
    end

    ::ShippingAgent::Notification.add_observer(Notification.new)
  end
end
