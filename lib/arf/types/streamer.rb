# frozen_string_literal: true

module Arf
  module Types
    class Streamer
      def self.[](type) = new(type)

      attr_accessor :type

      def initialize(type)
        @type = type
      end

      def resolved_type(resolver)
        return type if type.is_a? Symbol

        @resolved_type ||= resolver.find_type(type)
      end
    end
  end
end
