# frozen_string_literal: true

module Arf
  module Wire
    class WaitSignal
      def initialize
        @mutex = Mutex.new
        @cond = Thread::ConditionVariable.new
      end

      def wait
        @mutex.synchronize do
          @cond.wait(@mutex)
        end
      end

      def broadcast
        @mutex.synchronize do
          @cond.broadcast
        end
      end
    end
  end
end
