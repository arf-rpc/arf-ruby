# frozen_string_literal: true

module Arf
  module Proto
    def self.fields_from_struct(v)
      base = v.is_a?(Class) ? v : v.class
      fields = []
      base.fields.each do |f|
        fields << if f[:type].is_a?(Symbol) ||
                     f[:type].is_a?(Arf::Types::ArrayType) ||
                     f[:type].is_a?(Arf::Types::MapType)
                    f
                  else
                    {
                      id: f[:id],
                      name: f[:name],
                      type: base.find_type(f[:type])
                    }
                  end
      end

      fields.sort_by! { _1[:id] }
      fields
    end

    def self.encode_struct(v)
      struct_id = v.arf_struct_id
      fields = fields_from_struct(v)
      data = []
      fields.each do |f|
        data << encode_uint64(f[:id])
        data << encode_as(v.instance_variable_get("@#{f[:name]}"), f[:type])
      end

      payload = data.join

      [
        [TYPE_STRUCT].pack("C*"),
        encode_string(struct_id),
        encode_uint64(payload.length),
        payload
      ].join
    end

    def self.decode_struct(_header, io)
      id_type, id_header = read_type(io)
      if id_type != TYPE_STRING
        # :nocov:
        raise DecodeFailedError, "cannot decode struct: expected String, found #{TYPE_NAME[id_type]}"
        # :nocov:
      end

      struct_id = decode_string(id_header, io)
      bytes_len = decode_uint64(io)
      reader = IO::LimitReader.new(io, bytes_len)
      fields = {}
      loop do
        id = decode_uint64(reader)
        fields[id] = decode(reader)
      rescue EOFError
        break
      end

      meta_str = Registry.find(struct_id)
      raise UnknownMeessageError, "Unknown message ID #{struct_id}" unless meta_str

      inst = meta_str[:type].new
      inst.decode_fields(fields)
    end
  end
end
