require "singleton"
require "observer"

module ShippingAgent
  class Notification
    include Singleton
    include Observable

    def self.add_observer(*args)
      instance.add_observer(*args)
    end

    def self.update(*args)
      instance.update(*args)
    end

    def update(status, description, deploy)
      changed
      notify_observers(status, description, deploy)
    end
  end
end
