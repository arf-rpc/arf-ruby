# frozen_string_literal: true

module Arf
  module Wire
    class DataFrame < BaseFrame
      frame_kind :data
      wants_stream_id!

      define_flag :end_stream, 0
      define_flag :end_data, 1

      attr_accessor :payload

      def from_frame(fr)
        @payload = fr.payload
      end

      def encode_payload = @payload
    end
  end
end
