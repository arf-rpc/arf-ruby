# frozen_string_literal: true

module Arf
  module Wire
    class ResetStreamFrame < BaseFrame
      frame_kind :reset_stream
      value_size 4
      wants_stream_id!
      attr_accessor :error_code

      def from_frame(fr)
        @stream_id = fr.stream_id
        @error_code = decode_uint32(fr.payload)
      end

      def encode_payload = encode_uint32(error_code)
    end
  end
end
