require "feature_helper"
require "shipping_agent/webhook"

RSpec.describe ShippingAgent::Webhook do
  def app
    ShippingAgent::Webhook
  end

  describe "GET /" do
    it "works" do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to eq("ShippingAgent")
    end
  end
end
