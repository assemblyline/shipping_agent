require "feature_helper"
require "shipping_agent/github/webhook"
require "openssl"
require "json"
require "securerandom"

RSpec.describe ShippingAgent::Github::Webhook do
  let(:secret) { "thisissekret" }
  let(:body) { '{"foo":"bar"}' }

  def app
    described_class
  end

  before do
    app.secret = secret
  end

  describe "GET" do
    it "identifies what this is" do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to eq("ShippingAgent")
    end

    it "does not run the deployer" do
      expect(ShippingAgent::Deploy).to_not receive(:deploy)
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

      it "does not run the deployer" do
        expect(ShippingAgent::Deploy).to_not receive(:deploy)
        post "/", body
      end

      context "ping" do
        it "returns 200" do
          header "X-GitHub-Event", "ping"
          post "/", body
          expect(last_response).to be_unauthorized
        end
      end
    end

    context "the request is authorized" do
      before do
        header "X-Hub-Signature", "sha1=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret, body)
      end

      context "ping" do
        it "returns 200" do
          header "X-GitHub-Event", "ping"
          post "/", body
          expect(last_response).to be_ok
        end
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
        let(:id)  { rand(1..10_000) }
        let(:sha) { SecureRandom.hex }
        let(:build) { rand(1..234_565).to_s }
        let(:namespace) { %w(staging sandbox production).sample }
        let(:app_name) { %w(catnip dogfood fishflakes).sample }
        let(:deployment) do
          {
            url: url,
            id: id,
            environment: namespace,
            payload: {
              image: "quay.io/reevoo/#{app_name}:#{sha}_#{build}",
            },
            creator: { login: "errm" },
            description: "My Awesome Deploy",
          }
        end
        let(:body) { JSON.dump(deployment: deployment) }

        before { header "X-GitHub-Event", "deployment" }

        it "initiates the deploy" do
          expect(ShippingAgent::Deploy).to receive(:deploy).with(
            namespace: namespace,
            image: "quay.io/reevoo/#{app_name}:#{sha}_#{build}",
            app: app_name,
            labels: {
              deploy: "github.#{id}",
              build:  build,
              version:    sha,
            },
            deployment_url: url,
            creator: { "login" => "errm" },
            description: "My Awesome Deploy",
          )
          post "/", body
          expect(last_response).to be_accepted
        end

        context "without an image in the payload" do
          let(:deployment) do
            {
              url: url,
              id: id,
              environment: namespace,
              payload: {},
            }
          end

          # TODO, we should notify the user somehow

          it "returns a 400" do
            expect(ShippingAgent::Deploy).to_not receive(:deploy)
            post "/", body
            expect(last_response).to be_bad_request
          end
        end

        context "which is malformed" do
          context "with non-JSON data" do
            let(:body) { "wellthisisntirght" }

            it "returns a 400" do
              expect(ShippingAgent::Deploy).to_not receive(:deploy)
              post "/", body
              expect(last_response).to be_bad_request
            end
          end

          context "with unexpected JSON" do
            let(:body) { JSON.dump(deployment: {}) }

            it "returns a 400" do
              expect(ShippingAgent::Deploy).to_not receive(:deploy)
              post "/", body
              expect(last_response).to be_bad_request
            end
          end
        end
      end
    end
  end
end
