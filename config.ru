$LOAD_PATH.unshift File.expand_path("./lib", File.dirname(__FILE__))
require "shipping_agent/github/webhook"

ShippingAgent::Github::Webhook.secret = ENV.fetch("GITHUB_WEBHOOK_SECRET")
run ShippingAgent::Github::Webhook
