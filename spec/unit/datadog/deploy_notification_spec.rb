require "spec_helper"
require "shipping_agent/datadog/deploy_notification"

RSpec.describe ShippingAgent::Datadog::DeployNotification do
  let(:deploy) do
    double(
      :deploy,
      app:    "my_app",
      namespace: "production",
      labels: {
        version: "f255129c9944d5a597e15e5c11118bd03cb220ad",
        build:   "1234",
        deploy:  "github:1233456",
      },
      url: "https://github/deployment/1",
    )
  end

  let(:status) { "success" }
  let(:description) { "Deploy Notification Description" }
  let(:datadog) { double(:datadog, event: true) }


  describe "#update" do
    it "Sends a notification event to Datadog" do
      expect(::Datadog::Statsd).to receive(:new).and_return(datadog)

      expect(datadog).to receive(:event) do |key, text, opts|
        expect(key).to eq("my_app.production.deploy")
        expect(text).to eq("SHA: f255129c9944d5a597e15e5c11118bd03cb220ad  \\nBuild: 1234  \\nDeploy: github:1233456  \\nURL: https://github/deployment/1") # rubocop:disable Metrics/LineLength
        expect(opts).to eq(aggregation_key: "my_app.production.deploy")
      end

      described_class.new.update(status, description, deploy)
    end

    context "status is not success" do
      let(:status) { "error" }

      it "skips the notification" do
        expect(::Datadog::Statsd).to_not receive(:new)

        described_class.new.update(status, description, deploy)
      end
    end

    context "status is not success" do
      let(:status) { "error" }

      it "skips the notification" do
        expect(::Datadog::Statsd).to_not receive(:new)

        described_class.new.update(status, description, deploy)
      end
    end

    context "there is an error with the notification" do
      it "logs the error" do
        allow(::Datadog::Statsd).to receive(:new).and_raise
        expect(ShippingAgent::LOGGER).to receive(:warn)
        described_class.new.update(status, description, deploy)
      end
    end
  end
end
