# frozen_string_literal: true

module Arf
  module IO
    class LimitReader
      def initialize(io, size)
        @io = io
        @left = size
      end

      def readpartial(size)
        size = normalize_size(size)
        @io.readpartial(size).tap { @left -= _1.length }
      end

      def read(size)
        size = normalize_size(size)
        @io.read(size).tap { @left -= _1.length }
      end

      private

      def normalize_size(size)
        raise EOFError if @left.zero?

        [@left, size].min
      end
    end
  end
end
