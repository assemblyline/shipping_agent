# frozen_string_literal: true
require "datadog/statsd"
require "shipping_agent/logger"
require "shipping_agent/notification"

module ShippingAgent
  module Datadog
    class DeployNotification
      DEFAULT_STATSD_URL = "udp://localhost:8125"

      def update(status, description, deploy)
        return unless status == "success"

        Notifier.notify(status, deploy)
      rescue => e
        LOGGER.warn do
          "Failed to update datadog with: #{description} - due to: #{e.class} #{e.message}"
        end
      end

      class Notifier
        def self.notify(status, deploy)
          new(status, deploy).notify
        end

        def initialize(status, deploy)
          statsd_url = ENV.fetch("STATSD_URL", DEFAULT_STATSD_URL)
          @uri       = URI.parse(statsd_url)
          @datadog   = ::Datadog::Statsd.new(@uri.host, @uri.port)
          @status    = status
          @deploy    = deploy
        end

        def notify
          @datadog.event(event_key, event_text,  aggregation_key: event_key)
        end

        private

        def event_key
          @_event_key ||= [@deploy.app, @deploy.namespace, "deploy"].join(".")
        end

        def event_text
          [
            "SHA: #{@deploy.labels[:version]}",
            "Build: #{@deploy.labels[:build]}",
            "Deploy: #{@deploy.labels[:deploy]}",
            "URL: #{@deploy.url}",
          ].join('  \n')
        end
      end
    end

    ::ShippingAgent::Notification.add_observer(DeployNotification.new)
  end
end
