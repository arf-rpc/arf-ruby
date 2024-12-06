# frozen_string_literal: true

module Arf
  module RPC
    class MethodMeta
      Streamer = Arf::Types::Streamer
      InOutStream = Arf::Types::InOutStream

      ANY_STREAMER = ->(v) { v.is_a?(Streamer) || v.is_a?(InOutStream) }
      NOT_STREAMER = ->(v) { !v.is_a?(Streamer) && !v.is_a?(InOutStream) }

      def initialize(inputs, outputs)
        @inputs = inputs || {}
        @outputs = outputs || []
      end

      def output_stream = @outputs.find(&ANY_STREAMER)
      def input_stream = @inputs.values.find(&ANY_STREAMER)
      def output_stream? = !output_stream.nil?
      def input_stream? = !input_stream.nil?
      def output? = @outputs.any?(&NOT_STREAMER)
      def inputs? = @inputs.values.any?(&NOT_STREAMER)
      def output_types = @outputs.filter(&NOT_STREAMER)

      def coerce_result(value, resolver)
        return [] if value.nil?

        [value].flatten.map.with_index do |v, idx|
          expected_type = output_types[idx]
          case expected_type
          when String
            Arf::Types.coerce_value(v, resolver.find_type(expected_type))
          when Arf::Types::BaseType
            expected_type.coerce(v)
          else
            Arf::Types.coerce_value(v, expected_type)
          end
        end
      end
    end
  end
end
