require 'shipping_agent/process'

module ShippingAgent
  class Procfile
    def initialize(procfile_string)
      @entries = parse(procfile_string)
    end

    def processes
      @entries.map do |name, command|
        Process.new(name: name, command: command)
      end
    end

    private

    def parse(procfile_string)
      procfile_string.gsub("\r\n", "\n").split("\n").map do |line|
        if line =~ /^([A-Za-z0-9_-]+):\s*(.+)$/
          [Regexp.last_match[1], Regexp.last_match[2]]
        end
      end.compact
    end
  end
end
