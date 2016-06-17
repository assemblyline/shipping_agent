require "feature_helper"
require "shipping_agent/github/webhook"
require "openssl"
require "json"
require "securerandom"

RSpec.describe "Deploying To Kubernetes" do
  let(:secret) { "thisissekret" }
  let(:url) { "https://api.github.com/repos/assemblyline/dogfood/deployments/1" }
  let(:id)  { rand(1..10_000) }
  let(:sha) { SecureRandom.hex }
  let(:build) { rand(1..234_565).to_s }
  let(:namespace) { "production" }
  let(:app_name) { "dogfood" }
  let(:deployment) do
    {
      url: url,
      id: id,
      environment: namespace,
      payload: {
        image: "quay.io/reevoo/#{app_name}:#{sha}_#{build}",
      },
    }
  end
  let(:body) { JSON.dump(deployment: deployment) }

  def app
    ShippingAgent::Github::Webhook
  end

  before do
    app.secret = secret

    ENV["KUBERNETES_SERVICE_HOST"] = "foo.kube.local"

    ShippingAgent::Worker.purge
    ShippingAgent::Worker.run

    allow(File).to receive(:read)
      .with("/var/run/secrets/kubernetes.io/serviceaccount/token")
      .and_return("iAMtheTOKEN")

    stub_request(
      :get,
      "https://foo.kube.local/apis/extensions/v1beta1/namespaces/production/deployments?labelSelector=app=dogfood",
    ).with(
      headers: {
        "Accept" => "application/json",
        "Authorization" => "Bearer iAMtheTOKEN",
        "Host" => "foo.kube.local",
        "User-Agent" => "Ruby",
      },
    ).to_return(
      status: 200,
      body: JSON.dump(
        "items" => [
          { "metadata" => { "name" => "dogfood-can" } },
          { "metadata" => { "name" => "dogfood-bowl" } },
        ],
      ),
      headers: {},
    )

    stub_request(:patch, %r{https://foo\.kube\.local/.*})
      .to_return(status: 200, body: JSON.dump({}))

    %w(dogfood-can dogfood-bowl).each { |name| stub_status_request(name) }
  end

  def stub_status_request(name)
    stub_request(
      :get,
      "https://foo.kube.local/apis/extensions/v1beta1/namespaces/production/deployments/#{name}",
    ). with(
      headers: {
        "Accept" => "application/json",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => "Bearer iAMtheTOKEN",
        "Host" => "foo.kube.local",
        "User-Agent" => "Ruby",
      },
    ).to_return(
      status: 200,
      body: '{"status":{"replicas":1,"updatedReplicas":1,"availableReplicas":1}}',
      headers: {},
    )
  end

  it "patches the k8s deployments with the new metadata and image" do
    header "X-Hub-Signature", "sha1=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret, body)
    header "X-GitHub-Event", "deployment"

    expect(ShippingAgent::Notification).to receive(:update)
      .with("request", "Deployment of `dogfood` to `production` was requested",  an_instance_of(ShippingAgent::Deploy))
    expect(ShippingAgent::Notification).to receive(:update)
      .with("pending", "Config for dogfood-can pushed to kubernetes",  an_instance_of(ShippingAgent::Deploy))
    expect(ShippingAgent::Notification).to receive(:update)
      .with("pending", "Config for dogfood-bowl pushed to kubernetes", an_instance_of(ShippingAgent::Deploy))
    expect(ShippingAgent::Notification).to receive(:update)
      .with("success", "dogfood deployed sucessfully to production",   an_instance_of(ShippingAgent::Deploy))

    post "/", body

    expect(last_response).to be_accepted

    %w(dogfood-can dogfood-bowl).each do |deployment_name|
      expect(WebMock).to have_requested(
        :patch,
        "https://foo.kube.local/apis/extensions/v1beta1/namespaces/production/deployments/#{deployment_name}",
      ).with(
        body: JSON.dump(
          "metadata" => {
            "labels" => {
              "version" => sha,
              "build"   => build,
              "deploy"  => "github.#{id}",
            },
          },
          "spec" => {
            "template" => {
              "metadata" => {
                "labels" => {
                  "version" => sha,
                  "build"   => build,
                  "deploy"  => "github.#{id}",
                },
              },
              "spec" => {
                "containers" => [
                  { "name" => "dogfood", "image" => "quay.io/reevoo/#{app_name}:#{sha}_#{build}" },
                ],
              },
            },
          },
        ),
        headers: {
          "Content-Type" => "application/strategic-merge-patch+json",
          "Authorization" => "Bearer iAMtheTOKEN",
        },
      )
    end

    ShippingAgent::Worker.stop
  end
end
