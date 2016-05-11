$LOAD_PATH.unshift File.expand_path("./lib", File.dirname(__FILE__))
require 'shipping_agent/webhook'

run ShippingAgent::Webhook
