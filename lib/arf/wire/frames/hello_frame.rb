# frozen_string_literal: true

module Arf
  module Wire
    class HelloFrame < BaseFrame
      frame_kind :hello
      define_flag :ack, 0
      define_flag :compression_gzip, 1
      attr_accessor :max_concurrent_streams

      def from_frame(frame)
        if !frame.empty? && frame.length != 4
          raise InvalidFrameLengthError, "invalid length for frame HELLO " \
                                         "expected 0 or 4 bytes, got #{frame.length}"
        end

        @max_concurrent_streams = decode_uint32(frame.payload) unless frame.empty?

        return unless @max_concurrent_streams && @max_concurrent_streams != 0 && !ack?

        raise InvalidFrameError, "received non-ack HELLO with " \
                                 "non-zero max_concurrent_streams"
      end

      def encode_payload
        return unless @max_concurrent_streams

        encode_uint32(@max_concurrent_streams)
      end
    end
  end
end
