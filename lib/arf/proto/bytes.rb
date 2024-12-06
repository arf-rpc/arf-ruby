# frozen_string_literal: true

module Arf
  module Proto
    BYTES_EMPTY_MASK = 0x01 << 4

    def self.encode_bytes(b)
      v = TYPE_BYTES

      if b.empty?
        v |= BYTES_EMPTY_MASK
        return [v].pack("C*")
      end

      IO::Buffer.new
        .write(v)
        .write_raw(encode_uint64(b.length))
        .write_raw(b)
        .string
    end

    def self.decode_bytes(header, io)
      return "" if header.anybits?(BYTES_EMPTY_MASK)

      size = decode_uint64(io)
      data = StringIO.new
      until size.zero?
        read = io.readpartial(size)
        data.write(read)
        size -= read.length
      end
      data.string
    end
  end
end
