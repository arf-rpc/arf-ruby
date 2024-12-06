# frozen_string_literal: true

module Arf
  module Wire
    class Stream
      class State
        attr_reader :code
        attr_accessor :error

        def initialize
          @code = :open
          @error = nil
        end

        def close
          @code = :closed
        end

        def close_local
          @code = case @code
                  when :open then :half_closed_local
                  when :half_closed_local then :half_closed_local
                  when :half_closed_remote, :closed then :closed
                  end
        end

        def close_remote
          @code = case @code
                  when :open then :half_closed_remote
                  when :half_closed_local, :closed then :closed
                  when :half_closed_remote then :half_closed_remote
                  end
        end

        def closed? = (@code == :closed)
        def remote_closed? = (@code == :half_closed_remote)
        def local_closed? = (@code == :half_closed_local)

        def may_reset_stream?
          raise @error if @error
          raise ClosedStreamError if closed?

          true
        end

        def may_receive_data?
          raise @error if @error
          raise ClosedStreamError if closed? || remote_closed?

          true
        end

        def may_send_reset_stream?
          raise @error if @error
          raise ClosedStreamError if closed? || local_closed?

          true
        end

        def may_send_data?
          raise @error if @error
          raise ClosedStreamError if closed? || local_closed?

          true
        end
      end
    end
  end
end
