require "spec_helper"
require "shipping_agent/k8s"

RSpec.describe ShippingAgent::K8s do
  before do
    ENV["KUBERNETES_SERVICE_HOST"] = "kube.foo.com"
    allow(File).to receive(:read)
      .with("/var/run/secrets/kubernetes.io/serviceaccount/token")
      .and_return("IamTHEtoken")
  end

  describe ".patch_deployment" do
    it "patches the named deployment" do
      stub_request(:patch, "https://kube.foo.com/apis/extensions/v1beta1/namespaces/kittens/deployments/fluff")
        .with(
          body: '{"foo":"bar"}',
          headers: {
            "Accept" => "application/json",
            "Content-Type" => "application/strategic-merge-patch+json",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer IamTHEtoken",
            "Host" => "kube.foo.com",
            "User-Agent" => "Ruby",
          },
        ).to_return(status: 200, body: '{"baz":"quix"}', headers: {})

      expect(
        subject.patch_deployment(name: "fluff", namespace: "kittens", body: { "foo" => "bar" }),
      ).to eq("baz" => "quix")
    end
  end

  describe ".deployments" do
    it "returns the list of deployments" do
      stub_request(:get, "https://kube.foo.com/apis/extensions/v1beta1/namespaces/kittens/deployments")
        .with(
          headers: {
            "Accept" => "application/json",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer IamTHEtoken",
            "Host" => "kube.foo.com",
            "User-Agent" => "Ruby",
          },
        ).to_return(status: 200, body: '{"items":["tomcat","moggy","fluff"]}', headers: {})

      expect(subject.deployments(namespace: "kittens")).to eq %w(tomcat moggy fluff)
    end

    context "with a label selector" do
      it "returns the filtered list of deployments" do
        stub_request(:get, "https://kube.foo.com/apis/extensions/v1beta1/namespaces/kittens/deployments?labelSelector=language%3Djava%2Ctype%3Dwebserver") # rubocop:disable Metrics/LineLength
          .with(
          headers: {
            "Accept" => "application/json",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer IamTHEtoken",
            "Host" => "kube.foo.com",
            "User-Agent" => "Ruby",
          },
        ).to_return(status: 200, body: '{"items":["tomcat"]}', headers: {})

        expect(
          subject.deployments(namespace: "kittens", selector: { language: "java", type: "webserver" }),
        ).to eq %w(tomcat)
      end
    end
  end
end
