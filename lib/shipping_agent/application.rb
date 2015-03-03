require 'shipping_agent/build'
require 'shipping_agent/release'

module ShippingAgent
  class Application
    def initialize(name:, repo:)
      self.name     = name
      self.repo     = repo
      self.builds   = []
      self.releases = []
    end

    def register_build(tag:, procfile:)
      builds << Build.new(
        application: self,
        tag: tag,
        procfile: procfile,
      )
    end

    def release(build_tag:, env:)
      release =  Release.new(
        build: build_for(build_tag),
        env: env,
      )
      release.submit
      releases << release
    end

    def build_for(tag)
      builds.detect { |b| b.tag == tag } || fail('A valid build must be specified to release')
    end

    attr_accessor :name, :repo, :builds, :releases
  end
end
