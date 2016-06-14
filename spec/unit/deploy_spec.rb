require "spec_helper"
require "shipping_agent/deploy"

RSpec.describe ShippingAgent::Deploy do
  subject { described_class.new(info) }

  describe "#apply" do
    let(:info) do
      {
        app:       "shipping-agent",
        build:     "1234",
        deploy:    "github:1233456",
        image:     "quay.io/assemblyline/shipping_agent:f255129c9944d5a597e15e5c11118bd03cb220ad_1234",
        namespace: "assemblyline",
        version:   "f255129c9944d5a597e15e5c11118bd03cb220ad",
      }
    end

    before do
      allow(ShippingAgent::K8s).to receive(:deployments)
        .with(namespace: "assemblyline", selector: { app: "shipping-agent" })
        .and_return([
          { "metadata" => { "name" => "shipping-agent-api" } },
          { "metadata" => { "name" => "shipping-agent-worker" } },
        ])
    end

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

    it "patches the image and metadata" do
      expect(ShippingAgent::K8s).to receive(:patch_deployment) do |args|
        expect(args[:body]).to eq(
          "metadata" => {
            "labels" => {
              "version" => info[:version],
              "build"   => info[:build],
              "deploy"  => info[:deploy],
            },
          },
          "spec" => {
            "template" => {
              "metadata" => {
                "labels" => {
                  "version" => info[:version],
                  "build"   => info[:build],
                  "deploy"  => info[:deploy],
                },
              },
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
end
