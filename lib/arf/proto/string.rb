# frozen_string_literal: true

module Arf
  module Proto
    STRING_EMPTY_MASK = 0x01 << 4

    def self.encode_string(s)
      t = TYPE_STRING
      if s.nil? || s.empty?
        t |= STRING_EMPTY_MASK
        return [t].pack("C*")
      end

      s = s.to_s.encode("UTF-8")

      [
        [t].pack("C*"),
        encode_uint64(s.bytesize),
        s
      ].join
    end

    def self.decode_string(header, io)
      return "" if header.anybits?(STRING_EMPTY_MASK)

      size = decode_uint64(io)
      data = StringIO.new
      until size.zero?
        read = io.readpartial(size)
        data.write(read)
        size -= read.length
      end
      data.string.encode("UTF-8")
    end
  end
end
