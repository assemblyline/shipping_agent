require 'spec_helper'
require 'shipping_agent/application'

describe ShippingAgent::Application do
  subject { described_class.new(name: 'awesome', repo: 'quay.io/assemblyline/awesome') }

  it 'has a name' do
    expect(subject.name).to eq 'awesome'
  end

  it 'has a repo' do
    expect(subject.repo).to eq 'quay.io/assemblyline/awesome'
  end

  describe '#register_build' do
    before do
      subject.register_build(tag: 'v1', procfile: 'web: bin/puma')
    end

    it 'creates a new build' do
      expect(subject.builds.size).to eq 1
    end

    it 'is a Build' do
      expect(subject.builds.first).to be_a ShippingAgent::Build
    end

    it 'the build is setup with the correct tag and processes' do
      build = subject.builds.first
      expect(build.processes.map(&:name)).to eq ['web']
      expect(build.tag).to eq 'v1'
    end
  end

  describe '#release' do
    context 'happy path' do
      before do
        subject.register_build(tag: 'v1', procfile: 'web: bin/puma')
        subject.release(build_tag: 'v1', env: { 'RACK_ENV' => 'production' })
      end

      it 'creates a new release' do
        expect(subject.releases.size).to eq 1
      end

      it 'is a Release' do
        expect(subject.releases.first).to be_a ShippingAgent::Release
      end

      it 'gets a generated tag' do
        expect(subject.releases.first.tag).to eq 'cc412b93cd651ba1db383b5f236282716df22c04'
      end

      it 'has the correct build' do
        expect(subject.releases.first.build).to eq subject.builds.first
      end
    end

    context 'no build exists' do
      it 'fails' do
        expect do
          subject.release(build_tag: 'v1', env: { 'RACK_ENV' => 'production' })
        end.to raise_error('A valid build must be specified to release')
      end
    end

    context 'the build is specified incorrectly' do
      it 'fails' do
        subject.register_build(tag: 'v1', procfile: 'web: bin/puma')
        expect do
          subject.release(build_tag: 'v2', env: { 'RACK_ENV' => 'production' })
        end.to raise_error('A valid build must be specified to release')
      end
    end
  end
end
