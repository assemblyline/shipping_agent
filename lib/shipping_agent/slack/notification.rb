require "slack-ruby-client"
require "shipping_agent/logger"
require "shipping_agent/notification"

module ShippingAgent
  module Slack
    class Notification
      def update(status, description, deploy)
        slack.channels_list["channels"].select { |c| c["is_member"] }.each do |channel|
          slack.chat_postMessage(
            channel: channel["id"],
            attachments: [Attachment.new(status, description, deploy).to_hash],
            as_user: true,
          )
        end
      rescue => e
        LOGGER.warn do
          "Failed to update slack with: #{description} - due to: #{e.class} #{e.message}"
        end
      end

      private

      class Attachment
        def initialize(status, description, deploy)
          @status      = status
          @description = description
          @deploy      = deploy
        end

        # From: https://github.com/github/hubot-scripts/blob/master/src/scripts/shipit.coffee
        SQUIRRELS = [
          "http://28.media.tumblr.com/tumblr_lybw63nzPp1r5bvcto1_500.jpg",
          "http://i.imgur.com/DPVM1.png",
          "http://d2f8dzk2mhcqts.cloudfront.net/0772_PEW_Roundup/09_Squirrel.jpg",
          "http://www.cybersalt.org/images/funnypictures/s/supersquirrel.jpg",
          "http://www.zmescience.com/wp-content/uploads/2010/09/squirrel.jpg",
          "https://dl.dropboxusercontent.com/u/602885/github/sniper-squirrel.jpg",
          "http://1.bp.blogspot.com/_v0neUj-VDa4/TFBEbqFQcII/AAAAAAAAFBU/E8kPNmF1h1E/s640/squirrelbacca-thumb.jpg",
          "https://dl.dropboxusercontent.com/u/602885/github/soldier-squirrel.jpg",
          "https://dl.dropboxusercontent.com/u/602885/github/squirrelmobster.jpeg",
        ]

        def to_hash
          {
            text: description,
            color: color,
            ts: Time.now.to_i,
            mrkdwn_in: ["text"],
          }.merge(request_info)
        end

        private

        attr_reader :status, :description, :deploy

        def request_info
          return {} unless status == "request"
          {
            title:       deploy.description,
            author_name: deploy.creator["login"],
            author_link: deploy.creator["html_url"],
            author_icon: deploy.creator["avatar_url"],
            thumb_url: SQUIRRELS.sample,
          }
        end

        def color
          case status
          when "success"
            "good"
          when "error"
            "danger"
          else
            "warning"
          end
        end
      end

      def slack
        @slack ||= ::Slack::Web::Client.new(token: ENV.fetch("SLACK_API_TOKEN"))
      end

    end

    ::ShippingAgent::Notification.add_observer(Notification.new)
  end
end
