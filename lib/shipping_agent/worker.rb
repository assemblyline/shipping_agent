require "singleton"
require "thread"
require "forwardable"
require "shipping_agent/logger"

module ShippingAgent
  class Worker
    include Singleton
    extend SingleForwardable

    def initialize
      @running = false
      purge
    end

    def_delegators :instance, :work, :run, :stop, :purge

    def purge
      @queue = Queue.new
    end

    def work(job)
      @queue << job
    end

    def run
      @thread = Thread.new do
        @running = true
        LOGGER.info { "Background worker started" }
        while @running
          # This sleep is needed or the loop goes berserk and
          # uses all the CPU when the queue is empty
          sleep 0.1 if @queue.empty?

          until @queue.empty?
            job = @queue.pop
            job.call
          end
        end
        LOGGER.info { "Background worker stopped" }
      end

      until @running
        # Don't return until the thread is ready to work
      end
    end

    def stop
      LOGGER.info { "Shutting down background worker gracefully" }
      @running = false
      @thread.join
    end
  end
end
