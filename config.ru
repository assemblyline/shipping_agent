$LOAD_PATH.unshift File.expand_path("./lib", File.dirname(__FILE__))
require "shipping_agent/github/webhook"
require "shipping_agent/github/notification"
require "shipping_agent/logger"

ShippingAgent::Github::Webhook.secret = ENV.fetch("GITHUB_WEBHOOK_SECRET")

use Rack::CommonLogger, ShippingAgent::LOGGER
run ShippingAgent::Github::Webhook
