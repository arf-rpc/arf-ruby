# frozen_string_literal: true

module Arf
  module Proto
    FLOAT64_MASK = 0x01 << 4
    FLOAT_EMPTY_MASK = 0x01 << 5
    FLOAT32_MIN_VALUE = -3.4028235e38
    FLOAT32_MAX_VALUE = 3.4028235e38

    def self.encode_float32(value)
      t = TYPE_FLOAT
      if value.zero?
        t |= FLOAT_EMPTY_MASK
        return [t].pack("C*")
      end

      [
        [t].pack("C*"),
        [value].pack("g").unpack("N").pack("L>")
      ].join
    end

    def self.encode_float64(value)
      t = TYPE_FLOAT | FLOAT64_MASK
      if value.zero?
        t |= FLOAT_EMPTY_MASK
        return [t].pack("C*")
      end

      [
        [t].pack("C*"),
        [value].pack("G").unpack("Q>").pack("Q>")
      ].join
    end

    def self.decode_float(header, io)
      return 0.0 if header.anybits?(FLOAT_EMPTY_MASK)

      bits = header.nobits?(FLOAT64_MASK) ? 32 : 64
      data = io.read(bits / 8)
      if bits == 32
        data.unpack("L>").pack("L>").unpack1("g")
      else
        data.unpack("Q>").pack("Q>").unpack1("G")
      end
    end
  end
end
