# frozen_string_literal: true

module Arf
  module Proto
    NUMERIC_SIGNED_MASK = 0x01 << 4
    NUMERIC_ZERO_MASK = 0x01 << 5
    NUMERIC_NEGATIVE_MASK = 0x01 << 6

    def self.encode_scalar(v, signed: false)
      type = TYPE_SCALAR
      type |= NUMERIC_SIGNED_MASK if signed
      type |= NUMERIC_ZERO_MASK if v.zero?
      if v.negative?
        type |= NUMERIC_NEGATIVE_MASK
        v *= -1
      end

      [
        [type].pack("C*"),
        v.zero? ? nil : encode_uint64(v)
      ].compact.join
    end

    def self.decode_scalar(header, io)
      return 0 if header.anybits?(NUMERIC_ZERO_MASK)

      v = decode_uint64(io)
      v *= -1 if header.anybits?(NUMERIC_NEGATIVE_MASK)
      v
    end

    def self.encode_uint64(v)
      bytes = []
      while v >= 0x80
        bytes << ((v & 0xFF) | 0x80)
        v >>= 7
      end
      bytes << v
      bytes.pack("C*")
    end

    def self.decode_uint64(io)
      x = 0
      s = 0
      b = 0
      loop do
        b = io.read(1).getbyte(0)
        return (x | (b << s)) if b < 0x80

        x |= ((b & 0x7f) << s)
        s += 7
      end
    end
  end
end
