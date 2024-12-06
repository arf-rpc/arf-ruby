# frozen_string_literal: true

module Arf
  module RPC
    class StreamMetadata < BaseMessage
      kind :stream_metadata
      has_metadata

      def encode = metadata.encode

      def decode(data)
        @metadata = Metadata.new.decode(data)
      end
    end
  end
end
