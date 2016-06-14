require "spec_helper"
require "shipping_agent/notification"

RSpec.describe ShippingAgent::Notification do
  describe ".notify" do
    let(:github) { double }

    before do
      ENV["GITHUB_TOKEN"] = "tokenFoo"
      allow(Octokit::Client).to receive(:new).with(access_token: "tokenFoo").and_return(github)
    end

    after do
      ENV["GITHUB_TOKEN"] = nil
      described_class.instance_variable_set(:"@github_client", nil)
    end

    it "notifies github" do
      expect(github).to receive(:create_deployment_status).with(
        "https://api.github.com/repos/octocat/example/deployments/1",
        "pending",
        accept: "application/vnd.github.ant-man-preview+json",
        description: "this is a notification test",
      )

      described_class.notify(
        "pending",
        "this is a notification test",
        "https://api.github.com/repos/octocat/example/deployments/1",
      )
    end
  end
end
