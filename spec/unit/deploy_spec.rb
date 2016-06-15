require "spec_helper"
require "shipping_agent/deploy"

RSpec.describe ShippingAgent::Deploy do
  subject { described_class.new(info) }
  let(:info) do
    {
      app:       "shipping_agent",
      image:     "quay.io/assemblyline/shipping_agent:f255129c9944d5a597e15e5c11118bd03cb220ad_1234",
      namespace: "assemblyline",
      labels: {
        version:   "f255129c9944d5a597e15e5c11118bd03cb220ad",
        build:     "1234",
        deploy:    "github:1233456",
      },
      deployment_url: "https://github/deployment/1",
    }
  end

  before do
    allow(ShippingAgent::K8s).to receive(:deployments)
      .with(namespace: "assemblyline", selector: { app: "shipping-agent" })
      .and_return([
        { "metadata" => { "name" => "shipping-agent-api" } },
        { "metadata" => { "name" => "shipping-agent-worker" } },
      ])
    allow(ShippingAgent::Notification).to receive(:update)
    allow(ShippingAgent::K8s).to receive(:patch_deployment)
  end

  describe "#apply" do
    it "patches the correct deployments" do
      expect(ShippingAgent::K8s).to receive(:patch_deployment) do |args|
        expect(args[:namespace]).to eq "assemblyline"
        expect(args[:name]).to eq "shipping-agent-api"
      end.once

      expect(ShippingAgent::K8s).to receive(:patch_deployment) do |args|
        expect(args[:namespace]).to eq "assemblyline"
        expect(args[:name]).to eq "shipping-agent-worker"
      end.once
      subject.apply
    end

    it "sets up a notification" do
      expect(ShippingAgent::Notification).to receive(:update)
        .with(
          "pending",
          "Config for shipping-agent-api pushed to kubernetes",
          subject,
        )
      expect(ShippingAgent::Notification).to receive(:update)
        .with(
          "pending",
          "Config for shipping-agent-worker pushed to kubernetes",
          subject,
        )
      subject.apply
    end

    it "patches the image and metadata" do
      expect(ShippingAgent::K8s).to receive(:patch_deployment) do |args|
        expect(args[:body]).to eq(
          "metadata" => { "labels" => info[:labels] },
          "spec" => {
            "template" => {
              "metadata" => { "labels" => info[:labels] },
              "spec" => {
                "containers" => [
                  {
                    "name" => "shipping-agent",
                    "image" => info[:image],
                  },
                ],
              },
            },
          },
        )
      end.twice

      subject.apply
    end
  end

  describe "#notify_when_complete" do
    it "waits for the deployment to be complete" do
      expect(ShippingAgent::K8s).to receive(:deployment)
        .with(namespace: "assemblyline", name: "shipping-agent-api")
        .and_return(ds(0, 2), ds(1, 3), ds(2, 2))
        .at_least(3).times

      expect(ShippingAgent::K8s).to receive(:deployment)
        .with(namespace: "assemblyline", name: "shipping-agent-worker")
        .and_return(ds(0, 2), ds(1, 3), ds(2, 2))
        .at_least(3).times

      expect(ShippingAgent::Notification).to receive(:update)
        .with("success", "shipping-agent deployed sucessfully to assemblyline", subject)

      subject.notify_when_complete
    end

    def ds(updated, available)
      {
        "status" => {
          "replicas" => 2,
          "updatedReplicas" => updated,
          "availableReplicas" => available,
        },
      }
    end
  end
end
