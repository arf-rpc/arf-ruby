# frozen_string_literal: true

module Arf
  module RPC
    class StreamError < BaseMessage
      kind :stream_error
      has_status
      has_metadata

      def encode
        IO::Buffer.new
          .write_raw(encode_uint16(@status))
          .write_raw(metadata.encode)
          .string
      end

      def decode(data)
        @status = decode_uint16(data)
        @metadata = Metadata.new.decode(data)
      end
    end
  end
end
