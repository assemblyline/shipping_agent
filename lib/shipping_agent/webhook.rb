require "openssl"
require "json"

module ShippingAgent
  module Deployer
    extend self

    def notify(_url)
    end
  end

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
      return "400" unless env["HTTP_X_GITHUB_EVENT"]
      return "422" unless env["HTTP_X_GITHUB_EVENT"] == "deployment"
      url = url(body)
      return "400" if url.nil?

      Deployer.notify(url)
      "202"
    end

    def url(body)
      JSON.parse(body)["deployment"]["url"]
    rescue # rubocop:disable Lint/HandleExceptions
    end

    def response(code)
      [code, { "Content-Type" => "text/html" }, ["ShippingAgent"]]
    end

    def authorized?(signature:, body:)
      signature == "sha1=" + OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, body)
    end
  end
end
