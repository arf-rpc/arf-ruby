# frozen_string_literal: true

module Arf
  module Wire
    class PingFrame < BaseFrame
      frame_kind :ping
      value_size 8
      define_flag :ack, 2
      attr_accessor :payload

      def from_frame(fr)
        @payload = fr.payload
      end

      def encode_payload = @payload
    end
  end
end
