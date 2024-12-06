# frozen_string_literal: true

module Arf
  module Proto
    ARRAY_EMPTY_MASK = 0x01 << 4

    def self.encode_array(v)
      b = IO::Buffer.new
      t = TYPE_ARRAY
      if v.empty?
        t |= ARRAY_EMPTY_MASK
        return b.write(t).string if v.empty?
      end

      b.write(t).write_raw(encode_uint64(v.length))
      v.each { b.write_raw(encode(_1)) }
      b.string
    end

    def self.decode_array(header, io)
      return [] if header.anybits?(ARRAY_EMPTY_MASK)

      len = decode_uint64(io)
      arr = []
      len.times do
        arr << decode(io)
      end
      arr
    end
  end
end
