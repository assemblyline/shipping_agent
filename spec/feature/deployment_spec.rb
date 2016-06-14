require "feature_helper"
require "shipping_agent/github/webhook"
require "openssl"
require "json"
require "securerandom"

RSpec.describe "Deploying To Kubernetes" do
  let(:secret) { "thisissekret" }
  let(:url) { SecureRandom.hex }
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

    allow(File).to receive(:read)
      .with("/var/run/secrets/kubernetes.io/serviceaccount/token")
      .and_return("iAMtheTOKEN")

    stub_request(
      :get,
      "https://foo.kube.local/apis/extensions/v1beta1/namespaces/production/deployments?labelSelector=app=dogfood",
    ).with(
      headers: {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
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
  end

  it "patches the k8s deployments with the new metadata and image" do
    patch = {
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
    }

    expect(ShippingAgent::K8s).to receive(:patch_deployment).with(
      namespace: "production",
      name:      "dogfood-can",
      body:      patch,
    )

    expect(ShippingAgent::K8s).to receive(:patch_deployment).with(
      namespace: "production",
      name:      "dogfood-bowl",
      body:      patch,
    )

    header "X-Hub-Signature", "sha1=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret, body)
    header "X-GitHub-Event", "deployment"
    post "/", body
    expect(last_response).to be_accepted
  end
end
