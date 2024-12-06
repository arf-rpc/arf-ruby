# frozen_string_literal: true

module Arf
  module Wire
    class WireError < Arf::Error; end

    class FrameMismatchError < WireError
      attr_reader :expected, :received

      def initialize(expected, received)
        @expected = expected
        @received = received
        super("Frame type mismatch: Expected #{expected}, got #{received}")
      end
    end

    class UnexpectedUnassociatedFrameError < WireError
      attr_reader :kind

      def initialize(kind)
        @kind = kind
        super("Frame #{kind} must be associated to a stream")
      end
    end

    class UnexpectedAssociatedFrameError < WireError
      attr_reader :kind

      def initialize(kind)
        @kind = kind
        super("Frame #{kind} must not be associated to a stream")
      end
    end

    class InvalidFrameLengthError < WireError; end

    class InvalidFrameError < WireError; end

    class StreamResetError < WireError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super("Stream reset: #{Wire.error_code_to_string(reason)}")
      end
    end

    class StreamCanceledError < WireError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super("Stream canceled: #{Wire.error_code_to_string(reason)}")
      end
    end

    class ConnectionResetError < WireError
      attr_reader :reason, :details

      def initialize(reason, details = nil)
        @reason = reason
        @details = details
        super(if details
                "Connection reset: #{Wire.error_code_to_string(reason)} #{details}"
              else
                "Connection reset: #{Wire.error_code_to_string(reason)}"
              end)
      end
    end

    class UnknownFrameKindError < WireError
      attr_reader :received_kind

      def initialize(kind)
        @received_kind = kind
        if kind.is_a? Symbol
          super("Unknown frame kind 0x#{received_kind}")
        else
          super("Unknown frame kind 0x#{received_kind.to_s(16)}")
        end
      end
    end

    class MagicNumberMismatchError < WireError; end

    class ClosedStreamError < WireError; end
  end
end
