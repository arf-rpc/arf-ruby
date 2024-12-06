# frozen_string_literal: true

module Arf
  module Types
    class MapType < BaseType
      attr_reader :key, :value

      def initialize(k, v)
        super()
        @key = k
        @value = v
      end

      def self.[](k, v) = new(k, v)

      def resolved_types
        return @resolved_types if @resolved_types

        key = resolve_type(@key)
        value = resolve_type(@value)
        @resolved_types = [key, value]
      end

      def coerce(val)
        key_type, value_type = resolved_types
        val
          .transform_keys { coerce_value(_1, key_type) }
          .transform_values { coerce_value(_1, value_type) }
      end
    end
  end
end
