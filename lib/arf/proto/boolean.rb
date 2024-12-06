# frozen_string_literal: true

module Arf
  module Proto
    BOOL_FLAG_MASK = 0x01 << 4

    def self.encode_boolean(b)
      v = TYPE_BOOLEAN
      v |= BOOL_FLAG_MASK if b
      [v].pack("C*")
    end

    def self.decode_boolean(header, _io) = header.allbits?(BOOL_FLAG_MASK)
  end
end
