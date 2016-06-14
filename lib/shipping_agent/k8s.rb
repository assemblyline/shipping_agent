require "net/http"
require "json"
require "uri"
require "shipping_agent/logger"

module ShippingAgent
  module K8s
    extend self

    def deployments(namespace:, selector: {})
      endpoint = endpoint_for("/apis/extensions/v1beta1/namespaces/#{namespace}/deployments")
      if selector.any?
        endpoint.query = "labelSelector=#{selector.map { |label| label.join("%3D") }.join("%2C")}"
      end
      LOGGER.debug { "getting: #{endpoint}" }
      response = get(endpoint)
      LOGGER.debug { "k8s deployments: #{response.inspect}" }
      response["items"]
    end

    def patch_deployment(name:, namespace:, body:)
      endpoint = endpoint_for("/apis/extensions/v1beta1/namespaces/#{namespace}/deployments/#{name}")
      LOGGER.debug { "patching: #{endpoint} with: #{body.inspect}" }
      response = patch(endpoint, body)
      LOGGER.debug { "k8s response: #{response.inspect}" }
      response
    end

    private

    def get(uri)
      req = Net::HTTP::Get.new(uri)
      perform(uri, req)
    end

    def patch(uri, body)
      req = Net::HTTP::Patch.new(uri)
      req.content_type = "application/strategic-merge-json-patch+json"
      req.body = JSON.dump(body)
      perform(uri, req)
    end

    def bearer_token
      File.read("/var/run/secrets/kubernetes.io/serviceaccount/token")
    end

    def perform(uri, request)
      http = Net::HTTP.new(uri.hostname, uri.port)
      auth(http, request)
      response = http.request(request)
      return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
      fail(
        RequestNotSucessfull,
        "Tried to #{request.class} #{uri.path}" \
        "with: #{request.body}" \
        "but failed with #{response.code} - #{response.body}",
      )
    end

    def auth(http, req)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      req["Authorization"] = "Bearer #{bearer_token}"
    end

    def endpoint_for(path)
      URI("https://#{ENV.fetch("KUBERNETES_SERVICE_HOST")}#{path}")
    end

    class RequestNotSucessfull < StandardError; end
  end
end
