# frozen_string_literal: true

module Arf
  module RPC
    class Response < BaseMessage
      kind :response
      has_status
      has_metadata
      has_streaming
      attr_accessor :params

      def encode
        flags = 0x00
        flags |= (0x01 << 0x00) if streaming?

        params = @params.map { Proto.encode(_1) }

        IO::Buffer.new
          .write_raw(encode_uint16(@status))
          .write(flags)
          .write_raw(@metadata.encode)
          .write_raw(encode_uint16(params.length))
          .write_raw(params.join)
          .string
      end

      def ok? = status == :ok

      def decode(data)
        @status = decode_uint16(data)
        flags = data.readbyte
        @streaming = !flags.nobits?((0x01 << 0x00))
        @metadata = Metadata.new.decode(data)
        len = decode_uint16(data)
        @params = []
        len.times { @params << Proto.decode(data) }
      end

      def result
        return @params if status == :ok

        raise Status::BadStatus.new(@status, @metadata.get("arf-status-description"))
      end
    end
  end
end
