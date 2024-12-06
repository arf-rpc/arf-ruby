# frozen_string_literal: true

module Arf
  module RPC
    class BaseMessage
      def self.register(kind, cls)
        @messages ||= {}
        @messages[kind] = cls
      end

      def self.message_by_kind(kind)
        @messages ||= {}
        @messages[kind]
      end

      def self.initialize_from(data)
        type = MESSAGE_KIND_FROM_BYTE[data.readbyte] || :invalid
        raise "Cannot decode invalid message" if type == :invalid

        instance = message_by_kind(type).new
        instance.decode(data)
        instance
      end

      def self.encode(message)
        IO::Buffer.new
          .write(MESSAGE_KIND_FROM_SYMBOL[message.kind])
          .write_raw(message.encode)
          .string
      end

      def self.has_status
        define_method(:status=) do |val|
          case val
          when Symbol
            @status = Status::FROM_SYMBOL[val]
            raise ArgumentError, "Invalid value #{val.inspect} for status: Unknown status" unless @status
          when Integer
            if Status::TO_SYMBOL[val].nil?
              raise ArgumentError, "Invalid value #{val.inspect} for status: Unknown status"
            end

            @status = val
          else
            raise ArgumentError, "Invalid value #{val.inspect} for status: Expected symbol or integer"
          end
        end

        define_method(:status) do
          return nil if @status.nil?

          Status::TO_SYMBOL[@status] || :unknown
        end
      end

      def self.has_metadata
        attr_reader :metadata

        define_method(:metadata=) do |val|
          case val
          when NilClass
            @metadata = Metadata.new
          when Metadata
            @metadata = val
          when Hash
            @metadata = Metadata.new(**val)
          else
            raise ArgumentError, "Invalid value #{val.inspect} for metadata: Expected nil, Arf::RPC::Metadata, or Hash"
          end
        end
      end

      def self.has_streaming
        attr_accessor :streaming

        define_method(:streaming?) { @streaming }
      end

      def self.kind(kind = nil)
        return @kind if kind.nil?

        @kind = kind
        define_method(:kind) { self.class.kind }
        BaseMessage.register(kind, self)
        kind
      end

      def initialize(**kwargs)
        kwargs.each { |k, v| send("#{k}=", v) }
        @params ||= [] if respond_to? :params=
        @streaming ||= false if respond_to? :streaming=
        @metadata ||= Metadata.new if respond_to? :metadata=
      end

      def encode = ""

      def decode(_data) = nil

      def decode_string(data)
        type, header = Proto.read_type(data)
        raise "Invalid message payload" if type != Proto::TYPE_STRING

        Proto.decode_string(header, data)
      end

      def decode_bytes(data)
        type, header = Proto.read_type(data)
        raise "Invalid message payload" if type != Proto::TYPE_BYTES

        Proto.decode_bytes(header, data)
      end

      def decode_uint16(data) = Wire.decode_uint16(data)
      def encode_uint16(value) = Wire.encode_uint16(value)
      def encode_string(str) = Proto.encode_string(str)
      def encode_bytes(data) = Proto.encode_bytes(data)
    end
  end
end
