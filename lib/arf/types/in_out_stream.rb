# frozen_string_literal: true

module Arf
  module Types
    class InOutStream
      def self.[](input, output) = new(input, output)

      attr_accessor :input, :output

      def initialize(input, output)
        @input = input
        @output = output
      end

      def resolved_input(resolver)
        return input if input.is_a? Symbol

        @resolved_input ||= resolver.find_type(input)
      end

      def resolved_output(resolver)
        return output if output.is_a? Symbol

        @resolved_output ||= resolver.find_type(output)
      end
    end
  end
end
