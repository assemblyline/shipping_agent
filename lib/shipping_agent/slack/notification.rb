# frozen_string_literal: true
require "slack-ruby-client"
require "shipping_agent/logger"
require "shipping_agent/notification"
require "shipping_agent/slack/attachment"
require "mini_cache"

module ShippingAgent
  module Slack
    class Notification
      def initialize
        @messages = MiniCache::Store.new
      end

      def update(status, description, deploy)
        slack.channels_list["channels"].select { |c| c["is_member"] }.each do |channel|
          post_or_update_message(channel["id"], status, description, deploy)
        end
      rescue => e
        LOGGER.warn do
          "Failed to update slack with: #{description} - due to: #{e.class} #{e.message}"
        end
      end

      private

      def post_or_update_message(channel, status, description, deploy)
        key = "#{channel}/#{deploy.url}"
        message =  {
          channel: channel,
          attachments: [Attachment.new(status, description, deploy).to_hash],
          as_user: true,
        }
        if (ts = @messages.get(key))
          set_ts(key, slack.chat_update(message.merge(ts: ts))["ts"])
        else
          set_ts(key, slack.chat_postMessage(message)["ts"])
        end
      end

      def set_ts(key, ts)
        @messages.set(key, ts, expires_in: ENV.fetch("DEPLOY_TIMEOUT", "300").to_i)
      end

      def slack
        @slack ||= ::Slack::Web::Client.new(token: ENV.fetch("SLACK_API_TOKEN"))
      end

    end
    ::ShippingAgent::Notification.add_observer(Notification.new)
  end
end
