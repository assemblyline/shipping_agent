module ShippingAgent
  class Process
    def initialize(name:, command:)
      @name = name
      @command = command
    end

    def exposes_port?
      %w(api web).any? { |type| name.downcase.include? type }
    end

    attr_reader :name, :command
  end
end
