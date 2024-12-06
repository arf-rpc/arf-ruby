# frozen_string_literal: true

module Arf
  module Proto
    def self.decode(io)
      type, header = read_type(io)
      case type
      when TYPE_VOID
        nil
      when TYPE_SCALAR
        decode_scalar(header, io)
      when TYPE_BOOLEAN
        decode_boolean(header, io)
      when TYPE_FLOAT
        decode_float(header, io)
      when TYPE_STRING
        decode_string(header, io)
      when TYPE_BYTES
        decode_bytes(header, io)
      when TYPE_ARRAY
        decode_array(header, io)
      when TYPE_MAP
        decode_map(header, io)
      when TYPE_STRUCT
        decode_struct(header, io)
      when TYPE_UNION
        decode_union(header, io)
      end
    end
  end
end
