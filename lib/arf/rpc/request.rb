# frozen_string_literal: true

module Arf
  module RPC
    class Request < BaseMessage
      kind :request
      has_streaming
      has_metadata
      attr_accessor :service, :method, :params

      def encode
        flags = 0x00
        flags |= (0x01 << 0x00) if streaming?

        params = @params.map { Proto.encode(_1) }

        IO::Buffer.new
          .write_raw(encode_string(@service))
          .write_raw(encode_string(@method))
          .write(flags)
          .write_raw(@metadata.encode)
          .write_raw(encode_uint16(params.length))
          .write_raw(params.join)
          .string
      end

      def decode(data)
        @service = decode_string(data)
        @method = decode_string(data)
        flags = data.readbyte
        @streaming = !flags.nobits?((0x01 << 0x00))
        @metadata = Metadata.new.decode(data)
        params_len = decode_uint16(data)
        @params = []
        params_len.times { @params << Proto.decode(data) }
      end
    end
  end
end
