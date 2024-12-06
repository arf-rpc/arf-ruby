# frozen_string_literal: true

module Arf
  module IO
    class Buffer
      def initialize
        @buf = StringIO.new
      end

      def write(v) = tap { write_raw([v].pack("C*")) }
      def write_raw(v) = tap { @buf.write(v) }
      def reset = @buf.tap(&:rewind).truncate(0)
      def length = @buf.length
      def rewind = @buf.rewind
      def read(*) = @buf.read(*)
      def string = @buf.tap(&:rewind).string

      def extract
        buf = @buf
        @buf = StringIO.new
        buf
      end
    end
  end
end
