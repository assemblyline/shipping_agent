$LOAD_PATH.unshift File.expand_path("./lib", File.dirname(__FILE__))
require "shipping_agent/github/webhook"
require "shipping_agent/github/notification"
require "shipping_agent/slack/notification"
require "shipping_agent/datadog/deploy_notification"
require "shipping_agent/logger"

ShippingAgent::Github::Webhook.secret = ENV.fetch("GITHUB_WEBHOOK_SECRET")

ShippingAgent::Worker.run
at_exit { ShippingAgent::Worker.stop }

use Rack::CommonLogger, ShippingAgent::LOGGER
run ShippingAgent::Github::Webhook
