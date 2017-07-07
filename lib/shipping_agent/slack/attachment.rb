# frozen_string_literal: true
module ShippingAgent
  module Slack
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
      ].freeze

      def to_hash
        {
          fallback: description,
          text: description,
          color: color,
          ts: Time.now.to_i,
          mrkdwn_in: ["text"],
          title: deploy.description,
          thumb_url: SQUIRRELS.sample,
        }.merge(user)
      end


      private

      attr_reader :status, :description, :deploy

      def user
        {
          author_name: deploy.creator["login"],
          author_link: deploy.creator["html_url"],
          author_icon: deploy.creator["avatar_url"],
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
  end
end
