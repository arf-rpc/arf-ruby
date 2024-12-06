# frozen_string_literal: true

module Arf
  module Proto
    EMPTY_MAP_MASK = 0x01 << 4

    def self.encode_map(v)
      t = TYPE_MAP
      if v.empty?
        t |= EMPTY_MAP_MASK
        return [t].pack("C*")
      end

      keys = []
      values = []
      v.each_pair do |key, value|
        keys << encode(key)
        values << encode(value)
      end

      encoded_len = encode_uint64(v.length)
      keys = keys.join
      values = values.join

      IO::Buffer.new
        .write(t)
        .write_raw(encode_uint64(keys.length + values.length + encoded_len.length))
        .write_raw(encoded_len)
        .write_raw(keys)
        .write_raw(values)
        .string
    end

    def self.decode_map(header, io)
      return {} if header.anybits?(EMPTY_MAP_MASK)

      decode_uint64(io) # Discard full length

      pairs_len = decode_uint64(io)
      keys = []
      values = []

      pairs_len.times { keys << decode(io) }
      pairs_len.times { values << decode(io) }

      keys.zip(values).to_h
    end
  end
end
