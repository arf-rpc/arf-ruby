# frozen_string_literal: true

module Arf
  module RPC
    class Metadata < BaseMessage
      def initialize(**kwargs)
        super()
        @pairs = {}
        @dirty = false
        @observer = Observer.new
        kwargs.each { |k, v| set(k, v) }
      end

      def attach_observer(obs)
        @observer.attach_handler(obs)
      end

      def add(k, v) = @observer.modify { _add(k, v) }

      def [](k) = @pairs[k]
      def get(k) = @pairs[k]&.first

      def []=(k, v)
        @observer.modify { _add(k, v) }
      end

      def set(k, v)
        v = [v] unless v.is_a? Array
        @observer.modify do
          @pairs[k] = []
          v.each { _add(k, _1) }
        end
      end

      def merge!(other)
        @observer.modify do
          other.each do |k, v|
            @pairs[k] ||= []
            @pairs[k].append(*v)
          end
          @dirty = true
        end
        self
      end

      def replace!(other)
        @observer.modify do
          @pairs = {}
          other.each do |k, v|
            @pairs[k] ||= []
            @pairs[k].append(*v)
          end
          @dirty = true
        end
        self
      end

      def key?(k) = @pairs.key?(k.to_s)
      alias has_key? key?

      def each(&block) = tap { @pairs.each(&block) }
      alias each_pair each

      def keys = @pairs.keys
      def each_key(&block) = tap { @pairs.keys(&block) }

      def dirty? = @dirty

      def encode
        pairs = []
        @pairs.each do |k, v|
          v.each { pairs << [k, _1] }
        end
        keys = IO::Buffer.new
        values = IO::Buffer.new
        pairs.each do |p|
          keys.write_raw(encode_string(p.first))
          values.write_raw(encode_bytes(p.last))
        end

        @dirty = false
        IO::Buffer.new
          .write_raw(encode_uint16(pairs.length))
          .write_raw(keys.string)
          .write_raw(values.string)
          .string
      end

      def decode(data)
        len = decode_uint16(data)
        keys = []
        values = []

        len.times { keys << decode_string(data) }
        len.times { values << decode_bytes(data) }

        @pairs = {}
        keys.zip(values).each { |pair| _add(*pair) }
        @dirty = false

        self
      end

      private

      def _add(k, v)
        k = k.to_s
        v = case v
            when String then v
            when StringIO then v.string
            else v.to_s
            end

        @pairs[k] ||= []
        @pairs[k] << v
        @dirty = true
      end
    end
  end
end
