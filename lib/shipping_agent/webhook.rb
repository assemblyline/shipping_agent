module ShippingAgent
  module Webhook
    extend self

    def call(_env)
      ["200", { "Content-Type" => "text/html" }, ["ShippingAgent"]]
    end
  end
end
