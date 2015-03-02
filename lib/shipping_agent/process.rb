module ShippingAgent
  class Process
    def initialize(name:, command:)
      @name = name
      @command = command
    end

    attr_reader :name, :command
  end
end
