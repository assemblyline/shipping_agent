require "openssl"
require "json"
require "shipping_agent/deploy"

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
        image      = deployment["payload"]["image"]

        {
          deploy: "github.#{deployment["id"]}",
          namespace: deployment["environment"],
          image:     image,
        }.merge(image_metadata(image))

      rescue # rubocop:disable Lint/HandleExceptions
      end

      def invalid?(params)
        [:deploy, :namespace, :image].any? { |p| params[p].nil? }
      end

      def image_metadata(image)
        tag = image.split(":").last.split("_")
        {
          app:      image.split("/").last.split(":").first,
          build:    tag.last,
          version:  tag.first,
        }
      end
    end
  end
end
