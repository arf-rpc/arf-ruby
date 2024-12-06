# frozen_string_literal: true

module Arf
  module IO
    class BaseCompressor
      def self.compress(value)
        return nil if value.nil?

        value = value.string if value.is_a? StringIO
        value = do_compress(value)
        value.is_a?(StringIO) ? value : StringIO.new(value)
      end

      def self.decompress(value)
        return nil if value.nil?

        value = value.string if value.is_a? StringIO
        value = do_decompress(value)
        value.is_a?(StringIO) ? value : StringIO.new(value)
      end
    end

    class NoneCompressor
      def self.compress(value) = value
      def self.decompress(value) = value
    end

    class GzipCompressor < BaseCompressor
      def self.do_compress(value) = Zlib::Deflate.deflate(value)
      def self.do_decompress(value) = Zlib::Inflate.inflate(value)
    end

    class BrotliCompressor < BaseCompressor
      def self.do_compress(value) = Brotli.deflate(value)
      def self.do_decompress(value) = Brotli.inflate(value)
    end

    COMPRESSOR = {
      none: NoneCompressor,
      gzip: GzipCompressor,
      brotli: BrotliCompressor
    }.freeze
  end
end
