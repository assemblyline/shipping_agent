require "feature_helper"
require "shipping_agent/webhook"
require "openssl"
require "json"
require "securerandom"

RSpec.describe ShippingAgent::Webhook do
  let(:secret) { "thisissekret" }
  let(:body)  { '{"foo":"bar"}' }

  def app
    ShippingAgent::Webhook
  end

  before do
    ShippingAgent::Webhook.secret = secret
  end

  describe "GET" do
    it "identifies what this is" do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to eq("ShippingAgent")
    end

    it "does not notify the deployer" do
      expect(ShippingAgent::Deployer).to_not receive(:notify)
      get "/"
    end
  end

  describe "POST" do
    context "the request is not authorized" do
      it "returns 403" do
        header "X-Hub-Signature", "Hi - I just made this up, let me in please"
        post "/", body
        expect(last_response).to be_unauthorized
      end

      it "does not notify the deployer" do
        expect(ShippingAgent::Deployer).to_not receive(:notify)
        post "/", body
      end
    end

    context "the request is authorized" do
      before do
        header "X-Hub-Signature", "sha1=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret, body)
      end

      context "without a deployment event" do
        it "returns 400" do
          post "/", body
          expect(last_response).to be_bad_request
        end
      end

      context "with a non-deployment event" do
        it "returns 422" do
          header "X-GitHub-Event", "foobar"
          post "/", body
          expect(last_response).to be_unprocessable
        end
      end

      context "with a deployment event" do
        let(:url) { SecureRandom.hex }
        let(:body) { JSON.dump(deployment: { url: url }) }

        before { header "X-GitHub-Event", "deployment" }

        it "notifies the deployer" do
          expect(ShippingAgent::Deployer).to receive(:notify).with(url)
          post "/", body
          expect(last_response).to be_accepted
        end

        context "which is malformed" do
          context "with non-JSON data" do
            let(:body) { "wellthisisntirght" }

            it "returns a 400" do
              expect(ShippingAgent::Deployer).to_not receive(:notify)
              post "/", body
              expect(last_response).to be_bad_request
            end
          end

          context "with unexpected JSON" do
            let(:body) { JSON.dump(deployment: {}) }

            it "returns a 400" do
              expect(ShippingAgent::Deployer).to_not receive(:notify)
              post "/", body
              expect(last_response).to be_bad_request
            end
          end
        end
      end
    end
  end
end
