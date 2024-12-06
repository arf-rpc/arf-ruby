# frozen_string_literal: true

module Arf
  module Proto
    def self.encode_union(v)
      selected = v.__arf_union_set_id
      f = fields_from_struct(v).find { _1[:id] == selected }
      payload = encode_as(v.instance_variable_get("@#{f[:name]}"), f[:type])

      [
        [TYPE_UNION].pack("C*"),
        encode_uint64(selected),
        payload
      ].join
    end

    def self.decode_union(_header, io)
      {
        union: true,
        id: decode_uint64(io),
        value: decode(io)
      }
    end
  end
end
