require 'spec_helper'
require 'shipping_agent/procfile'

describe ShippingAgent::Procfile do
  subject do
    described_class.new(
      "# This is an example procfile for testing\nfoo: bundle exec rake\nbar: bin/bar -c config/config.yml",
    )
  end

  describe 'processes' do
    it 'has 2 processes' do
      expect(subject.processes.size).to eq 2
      subject.processes.each do |entry|
        expect(entry).to be_a ShippingAgent::Process
      end
    end

    it 'gets the corect data from the procfile' do
      expect(subject.processes.first.name).to eq 'foo'
      expect(subject.processes.first.command).to eq 'bundle exec rake'

      expect(subject.processes.last.name).to eq 'bar'
      expect(subject.processes.last.command).to eq 'bin/bar -c config/config.yml'
    end
  end
end
