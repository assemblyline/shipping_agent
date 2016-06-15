require "singleton"
require "observer"
require "forwardable"

module ShippingAgent
  class Notification
    include Singleton
    include Observable
    extend SingleForwardable

    def_delegators :instance, :add_observer, :update

    def update(status, description, deploy)
      changed
      notify_observers(status, description, deploy)
    end
  end
end
