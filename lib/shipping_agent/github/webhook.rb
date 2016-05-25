require "openssl"
require "json"
require "shipping_agent/deployer"

module ShippingAgent
  module Github
    module Webhook
      extend self

      HMAC_DIGEST = OpenSSL::Digest.new("sha1")

      attr_accessor :secret

      def call(env)
        return response("200") unless env["REQUEST_METHOD"] == "POST"
        response(handle_hook(env))
      end

      def handle_hook(env)
        body = env["rack.input"].read
        return "401" unless authorized?(signature: env["HTTP_X_HUB_SIGNATURE"], body: body)

        case env["HTTP_X_GITHUB_EVENT"]
        when "deployment"
          deploy(url(body))
        when "ping"
          "200"
        when nil
          "400"
        else
          "422"
        end
      end

      def url(body)
        JSON.parse(body)["deployment"]["url"]
      rescue # rubocop:disable Lint/HandleExceptions
      end

      def deploy(url)
        return "400" if url.nil?

        ShippingAgent::Deployer.notify(url)
        "202"
      end

      def response(code)
        [code, { "Content-Type" => "text/html" }, ["ShippingAgent"]]
      end

      def authorized?(signature:, body:)
        signature == "sha1=" + OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, body)
      end
    end
  end
end
