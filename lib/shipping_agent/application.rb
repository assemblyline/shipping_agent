module ShippingAgent
  class Application
    def initialize(name:, repo:)
      self.name = name
      self.repo = repo
    end

    attr_accessor :name, :repo
  end
end
