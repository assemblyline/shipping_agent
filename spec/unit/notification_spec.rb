require "spec_helper"
require "shipping_agent/notification"

RSpec.describe ShippingAgent::Notification do
  describe ".update" do
    let(:deployment)       { double(:deployment) }
    let(:observer)         { double(:observer, update: nil) }
    let(:other_observer)   { double(:observer, update: nil) }

    it "notifies interested observers" do
      described_class.add_observer(observer)
      described_class.add_observer(other_observer)

      expect(observer).to receive(:update).with("pending", "hello", deployment)
      expect(other_observer).to receive(:update).with("pending", "hello", deployment)

      described_class.update("pending", "hello", deployment)
    end

    after do
      described_class.instance.delete_observers
    end
  end
end
