# frozen_string_literal: true

module Arf
  module Proto
    def self.encode(value)
      case value
      when NilClass
        [TYPE_VOID].pack("C*")
      when String, Symbol
        encode_string(value.to_s)
      when TrueClass, FalseClass
        encode_boolean(value)
      when Float
        if value.between?(FLOAT32_MIN_VALUE, FLOAT32_MAX_VALUE)
          encode_float32(value)
        else
          encode_float64(value)
        end
      when Integer
        encode_scalar(value, signed: value.negative?)
      when Array
        encode_array(value)
      when Hash
        encode_map(value)
      else
        unless value.class.ancestors.include? Arf::RPC::Struct
          raise InvalidEncodingTypeError, "Unable to encode value of type #{value.class.name}"
        end

        encode_struct(value)

      end
    end

    def self.encode_as(value, type)
      return [TYPE_VOID].pack("C*") if value.nil?

      case type
      when :uint8, :uint16, :uint32, :uint64
        encode_scalar(value, signed: false)
      when :int8, :int16, :int32, :int64
        encode_scalar(value, signed: true)
      when :float32
        encode_float32(value)
      when :float64
        encode_float64(value)
      when :bool
        encode_boolean(value)
      when :string
        encode_string(value)
      when :bytes
        encode_bytes(value)
      else
        if type.is_a?(Arf::Types::MapType)
          encode_map(value)
        elsif type.is_a?(Arf::Types::ArrayType)
          encode_array(value)
        elsif type.is_a?(String) && value.class.ancestors.include?(Arf::RPC::Struct)
          encode_struct(value)
        elsif type.is_a?(Class) && type.ancestors.include?(Arf::RPC::Struct)
          encode_struct(value)
        elsif type.is_a?(Class) && type.ancestors.include?(Arf::RPC::Enum)
          encode_scalar(type.to_i(value), signed: false)
        else
          raise InvalidEncodingTypeError,
                "Unable to encode value of type #{value.class.name} (reported type is #{type.inspect})"
        end
      end
    end
  end
end
