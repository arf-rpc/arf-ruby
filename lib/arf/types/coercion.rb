# frozen_string_literal: true

module Arf
  module Types
    def self.coerce_value(value, type)
      if Types::INTEGERS.include?(type)
        value.to_i
      elsif Types::FLOATS.include?(type)
        value.to_f
      elsif type == :string
        value.to_s
      elsif type == :bytes
        case value
        when StringIO then value.string
        when String then value
        when Array then value.pack("C*")
        else
          raise ArgumentError, "Invalid type for bytes: #{i.class.name}"
        end
      elsif type == :bool
        !!value
      elsif type.is_a?(Class)
        case value
        when Hash then type.new(**value)
        when type then value
        else
          raise ArgumentError,
                "Cannot initialize #{type} with #{value.inspect} (#{value.class}). " \
                "You may want to use an instance of #{type}, or a Hash"
        end
      elsif type.is_a?(Arf::Types::ArrayType) || type.is_a?(Arf::Types::MapType)
        type.coerce(value)
      end
    end
  end
end
