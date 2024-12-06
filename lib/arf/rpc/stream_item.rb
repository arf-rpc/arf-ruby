# frozen_string_literal: true

module Arf
  module RPC
    class StreamItem < BaseMessage
      kind :stream_item
      attr_accessor :value

      def encode = Proto.encode(@value)

      def decode(data)
        @value = Proto.decode(data)
      end
    end
  end
end
