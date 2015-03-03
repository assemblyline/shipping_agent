require 'shipping_agent/application'
require 'shipping_agent/build'
require 'shipping_agent/release'

require 'etcd'
require 'json'

module ShippingAgent
  module ApplicationRepository
    extend self

    def etcd
      Etcd.client(host: ENV['ETCD_HOST'])
    end

    def save(application)
      etcd.set("/assemblyline/applications/#{application.name}/application", value: to_json(application))
      application.builds.each do |build|
        save_build(build)
      end
      application.releases.each do |release|
        save_release(release)
      end
      true
    end

    def get(name)
      json = JSON.parse(etcd.get(path(name, 'application')).value)
      application = Application.new(name: json['name'], repo: json['repo'])
      application.builds = get_builds_for(application)
      application.releases = get_releases_for(application)
      application
    rescue Etcd::KeyNotFound
      nil
    end

    private


    def get_builds_for(application)
      data_map(application, 'builds') do |key|
        json = JSON.parse(etcd.get("#{key}/build").value)
        Build.new(application: application, tag: json['tag'], procfile: json['procfile'])
      end
    end

    def get_releases_for(application)
      data_map(application, 'releases') do |key|
        json = JSON.parse(etcd.get("#{key}/release").value)
        build = application.build_for(json['build_tag'])
        Release.new(build: build, env: json['env'], tag: json['tag'])
      end
    end

    def data_map(application, type)
      etcd.get(path(application.name, type)).children.map(&:key).map do |key|
        yield key
      end
    rescue Etcd::KeyNotFound
      []
    end

    def path(name, type)
      "/assemblyline/applications/#{name}/#{type}"
    end

    def save_build(build)
      etcd.set(
        "/assemblyline/applications/#{build.application.name}/builds/#{build.tag}/build",
        value: to_json(build),
      )
    end

    def save_release(release)
      etcd.set(
        "/assemblyline/applications/#{release.build.application.name}/releases/#{release.tag}/release",
        value: to_json(release),
      )
    end

    def to_json(obj) # rubocop:disable Metrics/MethodLength
      case obj.class.name
      when 'ShippingAgent::Application'
        {
          name: obj.name,
          repo: obj.repo,
        }
      when 'ShippingAgent::Build'
        {
          tag:      obj.tag,
          procfile: obj.procfile,
        }
      when 'ShippingAgent::Release'
        {
          tag: obj.tag,
          build_tag: obj.build.tag,
          env: obj.env,
        }
      end.to_json
    end
  end
end
