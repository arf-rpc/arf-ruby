# frozen_string_literal: true

module Arf
  module Types
    class ArrayType < BaseType
      attr_reader :type

      def initialize(v)
        super()
        @type = v
      end

      def self.[](v) = new(v)

      def resolved_type
        @resolved_type ||= resolve_type(@type)
      end

      def bind(to) = tap { @bind = to }

      def coerce(val) = val.map { coerce_value(_1, resolved_type) }
    end
  end
end
