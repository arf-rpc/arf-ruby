# frozen_string_literal: true

module Arf
  module Wire
    class BaseFrame
      def self.register_frame(kind, cls)
        @frames ||= {}
        @frames[kind] = cls
      end

      def self.frame_by_kind(kind) = @frames[kind]

      def self.frame_kind(name = nil)
        BaseFrame.register_frame(name, self) if name
        @frame_kind ||= name
      end

      def self.value_size(size = nil)
        @value_size ||= size
      end

      def self.wants_stream_id!
        attr_accessor :stream_id

        @wants_stream_id = true
      end

      def self.wants_stream_id?
        @wants_stream_id || false
      end

      def self.define_flag(name, offset)
        @flags ||= {}
        @flags[name] = offset
        define_method("#{name}!") do
          instance_variable_set("@#{name}", true)
        end

        define_method("#{name}?") do
          instance_variable_get("@#{name}") || false
        end
      end

      def self.flags
        @flags || {}
      end

      def initialize(frame = nil)
        if frame
          frame.validate_kind(frame_kind, wants_stream_id?)
          frame.validate_size(value_size) unless value_size.nil?
          @stream_id = frame.stream_id if wants_stream_id?
          decode_flags(frame)
          from_frame(frame)
        end
        yield self if block_given?
      end

      def frame_kind = self.class.frame_kind
      def wants_stream_id? = self.class.wants_stream_id?
      def value_size = self.class.value_size
      def from_frame(_frame) = nil
      def encode_payload = nil
      def flags = self.class.flags

      # :nocov:

      def inspect_flags
        flags.keys.to_h do |k|
          [k, instance_variable_get("@#{k}")]
        end
      end

      # :nocov:

      def encode_uint16(*) = Wire.encode_uint16(*)
      def encode_uint32(*) = Wire.encode_uint32(*)
      def decode_uint16(*) = Wire.decode_uint16(*)
      def decode_uint32(*) = Wire.decode_uint32(*)

      def encode_flags
        value = 0x00
        flags.each_pair do |name, offset|
          value |= (0x01 << offset) if send("#{name}?")
        end
        value
      end

      def decode_flags(frame)
        flags.each_pair do |name, offset|
          send("#{name}!") if frame.flags.anybits?((0x01 << offset))
        end
      end

      def to_frame
        Frame.new.tap do |f|
          f.stream_id = stream_id if wants_stream_id?
          f.frame_kind = frame_kind
          f.flags = encode_flags
          payload = encode_payload
          payload = StringIO.new(payload) if payload && !payload.is_a?(StringIO)
          f.length = (payload || "").length
          f.payload = payload
        end
      end
    end
  end
end
