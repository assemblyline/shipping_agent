require 'spec_helper'
require 'shipping_agent/process'

describe ShippingAgent::Process do
  subject { described_class.new(name: 'foo', command: 'bundle exec rake foo') }

  it 'has a name and command' do
    expect(subject.name).to eq 'foo'
    expect(subject.command).to eq 'bundle exec rake foo'
  end

  describe '#exposes_port?' do

    it 'exposes port if the name is web' do
      expect(process('web').exposes_port?).to be_truthy
    end

    it 'exposes port if the name includes web' do
      expect(process('awesome_web-service').exposes_port?).to be_truthy
    end

    it 'exposes port if the name is api' do
      expect(process('api').exposes_port?).to be_truthy
    end

    it 'exposes port if the name includes api (case insensitive)' do
      expect(process('the deprecatied V2 API').exposes_port?).to be_truthy
    end

    it 'does not expose port if the name is something else' do
      expect(process('worker').exposes_port?).to be_falsey
      expect(process('pirate').exposes_port?).to be_falsey
      expect(process('service').exposes_port?).to be_falsey
    end

  end

  describe '#port' do

    it 'is nil when not exposing a port' do
      expect(process('sidekick').port).to be_nil
    end

    it 'is 3333 when exposing a port' do
      expect(process('web').port).to eq 3333
    end
  end

  def process(name)
    described_class.new(name: name, command: 'whatever')
  end
end
