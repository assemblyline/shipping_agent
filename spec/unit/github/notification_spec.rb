require "spec_helper"
require "shipping_agent/github/notification"

RSpec.describe ShippingAgent::Github::Notification do
  let(:github) { double }

  before do
    ENV["GITHUB_TOKEN"] = "tokenFoo"
    allow(Octokit::Client).to receive(:new).with(access_token: "tokenFoo").and_return(github)
  end

  after do
    ENV["GITHUB_TOKEN"] = nil
    subject.instance_variable_set(:"@github_client", nil)
  end
  it "notifies github" do
    expect(github).to receive(:create_deployment_status).with(
      "https://api.github.com/repos/octocat/example/deployments/1",
      "pending",
      accept: "application/vnd.github.ant-man-preview+json",
      description: "this is a notification test",
    )

    subject.update(
      "pending",
      "this is a notification test",
      double(:deployment, url: "https://api.github.com/repos/octocat/example/deployments/1"),
    )
  end
end
