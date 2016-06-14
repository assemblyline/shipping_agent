require "openssl"
require "json"
require "shipping_agent/deploy"
require "shipping_agent/logger"

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
        LOGGER.debug { "raw webhook: #{body}" }
        return "401" unless authorized?(signature: env["HTTP_X_HUB_SIGNATURE"], body: body)

        case env["HTTP_X_GITHUB_EVENT"]
        when "deployment"
          deploy(deployment_params(body))
        when "ping"
          "200"
        when nil
          "400"
        else
          "422"
        end
      end

      def deploy(params)
        return "400" if params.nil? || invalid?(params)
        LOGGER.debug { "deployment params: #{params.inspect}" }
        ShippingAgent::Deploy.deploy(params)
        "202"
      end

      def response(code)
        [code, { "Content-Type" => "text/html" }, ["ShippingAgent"]]
      end

      def authorized?(signature:, body:)
        signature == "sha1=" + OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, body)
      end

      private

      def deployment_params(body)
        deployment = JSON.parse(body)["deployment"]
        image = deployment["payload"]["image"]
        {
          namespace: deployment["environment"],
          image:     image,
          app:       image.split("/").last.split(":").first,
          labels:    labels(deployment),
        }

      rescue # rubocop:disable Lint/HandleExceptions
      end

      def invalid?(params)
        [:namespace, :image, :labels].any? { |p| params[p].nil? }
      end

      def labels(deployment)
        tag = deployment["payload"]["image"].split(":").last.split("_")
        {
          version:  tag.first,
          build:    tag.last,
          deploy: "github.#{deployment["id"]}",
        }
      end
    end
  end
end
