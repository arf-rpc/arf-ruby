# frozen_string_literal: true

module Arf
  class Observer
    def initialize
      @handler = nil
      @primed = false
      @mutex = Monitor.new
    end

    def attach_handler(handler)
      @handler = handler
    end

    def prime
      @primed = true
    end

    def modify
      @mutex.synchronize do
        yield
        if @primed
          @primed = false
          Arf::Reactor.post { @handler.observer_changed(self) }
        end
      end
    end
  end
end
