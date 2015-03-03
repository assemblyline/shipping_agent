require 'shipping_agent/unit'
require 'digest'

module ShippingAgent
  class Release
    def initialize(build:, env:, tag: nil)
      self.build       = build
      self.env         = env
      self.tag         = tag || generate_tag
    end

    attr_reader :build, :tag, :env

    def to_unit(process_name)
      Unit.new(
        name: name,
        image: image,
        process: build.process(process_name),
        env: env,
      ).to_hash
    end

    protected

    attr_writer :build, :tag, :env

    private

    def image
      build.image
    end

    def name
      "#{build.application.name}_#{build.tag}_#{tag[0..8]}"
    end

    def generate_tag
      Digest::SHA1.hexdigest(build.application.name + build.tag + env.inspect)
    end
  end
end
