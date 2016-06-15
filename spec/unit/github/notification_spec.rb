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

  context "on a sucessfull deployment" do
    let(:deploy) do
      double(
        :deploy,
        url: "https://api.github.com/repos/octocat/example/deployments/3",
        rels: {
          repository: double(get: double(data: repo)),
          statuses: double(get: double(data: [double(state: "success")])),
        },
      )
    end

    let(:old_deploy) do
      double(
        :deploy,
        url: "https://api.github.com/repos/octocat/example/deployments/2",
        rels: {
          repository: double(get: double(data: repo)),
          statuses: double(get: double(data: [double(state: "success")])),
        },
      )
    end

    let(:inactive_deploy) do
      double(
        :deploy,
        url: "https://api.github.com/repos/octocat/example/deployments/1",
        rels: {
          repository: double(get: double(data: repo)),
          statuses: double(get: double(data: [double(state: "inactive")])),
        },
      )
    end

    let(:repo) { double(:repo, deployments_url: "https://api.github.com/repos/octocat/example/deployments") }

    let(:deployments) { [deploy, old_deploy, inactive_deploy] }

    before do
      allow(github).to receive(:get)
        .with("https://api.github.com/repos/octocat/example/deployments/3")
        .and_return(deploy)

      allow(github).to receive(:get)
        .with(
          "https://api.github.com/repos/octocat/example/deployments",
          environment: "production",
        )
        .and_return(deployments)
    end

    it "notifies github and marks the old deployments as inactive" do
      expect(github).to receive(:create_deployment_status).with(
        "https://api.github.com/repos/octocat/example/deployments/2",
        "inactive",
        accept: "application/vnd.github.ant-man-preview+json",
      )

      expect(github).to receive(:create_deployment_status).with(
        "https://api.github.com/repos/octocat/example/deployments/3",
        "success",
        accept: "application/vnd.github.ant-man-preview+json",
        description: "the deploy was a success",
      )

      subject.update(
        "success",
        "the deploy was a success",
        double(:deployment, url: "https://api.github.com/repos/octocat/example/deployments/3", namespace: "production"),
      )
    end
  end
end
