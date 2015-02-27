module ShippingAgent
  class Build
    def initialize(application:, tag:)
      self.application = application
      self.tag = tag
    end

    attr_reader :application

    def image
      "#{application.repo}:#{tag}"
    end

    protected

    attr_accessor :tag
    attr_writer :application
  end
end
