require 'shipping_agent/unit'
require 'shipping_agent/process'
require 'fleet'
require 'digest'

module ShippingAgent
  class Release
    def initialize(build:, env:, tag: nil)
      self.build       = build
      self.env         = env
      self.tag         = tag || generate_tag
    end

    attr_reader :build, :tag, :env

    def submit
      build.processes.each do |process|
        fleet.submit(name(process) + '@.service', to_unit(process))
        fleet.submit(name(process) + '_sidekick@.service', to_sidekick(process)) if process.exposes_port?
      end
    end

    def to_unit(process)
      Unit.new(
        name: name(process),
        image: image,
        process: process,
        env: env,
      ).to_hash
    end

    def to_sidekick(process)
      Unit.new(
        name: name(process) + '_sidekick',
        image: 'quay.io/assemblyline/sidekicks',
        process: Process.new(name: 'vulcand', command: 'vulcand'),
        env: {},
      ).to_hash
    end

    protected

    attr_writer :build, :tag, :env

    private

    def fleet
      Fleet.new
    end

    def image
      build.image
    end

    def name(process)
      "#{build.application.name}_#{build.tag}_#{tag[0..8]}_#{process.name}"
    end

    def generate_tag
      Digest::SHA1.hexdigest(build.application.name + build.tag + env.inspect)
    end
  end
end
