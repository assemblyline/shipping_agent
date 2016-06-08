require "curb"
require "json"

module ShippingAgent
  module K8s
    extend self

    def client
      return @client if @client
      @client = Curl::Easy.new
      @client.cacert = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      @client.headers = ["Authorization: Bearer #{bearer_token}"]
      @client
    end

    def bearer_token
      File.read("/var/run/secrets/kubernetes.io/serviceaccount/token")
    end

    def api_endpoint
      "https://#{ENV.fetch("KUBERNETES_SERVICE_HOST")}/api/v1"
    end

    def get(path)
      client.url = "#{api_endpoint}#{path}"
      client.perform
      JSON.parse(client.body_str)
    end

  end
end
