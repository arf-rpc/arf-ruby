# frozen_string_literal: true

module Arf
  module Wire
    class GoAwayFrame < BaseFrame
      frame_kind :go_away

      attr_accessor :last_stream_id, :error_code, :additional_data

      def from_frame(fr)
        if fr.length < 8
          raise InvalidFrameLengthError, "Invalid length for frame GOAWAY: at" \
                                         "least 8 bytes are required"
        end
        @last_stream_id = decode_uint32(fr.payload)
        @error_code = decode_uint32(fr.payload)
        @additional_data = fr.payload.read
      end

      def encode_payload
        buf = IO::Buffer.new
          .write_raw(encode_uint32(last_stream_id))
          .write_raw(encode_uint32(error_code))
        buf.write_raw(additional_data) if additional_data
        buf.string
      end
    end
  end
end
