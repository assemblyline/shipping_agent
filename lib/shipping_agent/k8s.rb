require "net/http"
require "json"
require "uri"

module ShippingAgent
  module K8s
    extend self

    def deployments(namespace:, selector: {})
      endpoint = endpoint_for("/apis/extensions/v1beta1/namespaces/#{namespace}/deployments")
      if selector.any?
        endpoint.query = "labelSelector=#{selector.map { |label| label.join("%3D") }.join("%2C")}"
      end
      get(endpoint)["items"]
    end

    def patch_deployment(name:, namespace:, body:)
      endpoint = endpoint_for("/apis/extensions/v1beta1/namespaces/#{namespace}/deployments/#{name}")
      patch(endpoint, body)
    end

    private

    def get(uri)
      req = Net::HTTP::Get.new(uri)
      perform(uri, req)
    end

    def patch(uri, body)
      req = Net::HTTP::Patch.new(uri)
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
