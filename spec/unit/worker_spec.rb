require "spec_helper"
require "shipping_agent/worker"

RSpec.describe ShippingAgent::Worker do
  before do
    ShippingAgent::Worker.instance.purge
  end

  it "does the work to completion" do
    @n = 0
    ShippingAgent::Worker.work(lambda do
      5.times do
        @n += 1
        sleep 0.01
      end
    end)
    ShippingAgent::Worker.run
    sleep 0.01
    ShippingAgent::Worker.stop
    expect(@n).to eq(5)
  end
end
