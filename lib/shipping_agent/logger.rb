require "logger"

module ShippingAgent
  LOGGER = Logger.new($stdout)
  LOGGER.level = Logger.const_get(ENV.fetch("LOG_LEVEL", "WARN"))
end
