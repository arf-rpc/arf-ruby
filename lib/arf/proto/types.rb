# frozen_string_literal: true

module Arf
  module Proto
    TYPE_VOID    = 0b0000
    TYPE_SCALAR  = 0b0001
    TYPE_BOOLEAN = 0b0010
    TYPE_FLOAT   = 0b0011
    TYPE_STRING  = 0b0100
    TYPE_BYTES   = 0b0101
    TYPE_ARRAY   = 0b0110
    TYPE_MAP     = 0b0111
    TYPE_STRUCT  = 0b1000
    TYPE_UNION   = 0b1001

    ALL_PRIMITIVES = [
      TYPE_VOID,
      TYPE_SCALAR,
      TYPE_BOOLEAN,
      TYPE_FLOAT,
      TYPE_STRING,
      TYPE_BYTES,
      TYPE_ARRAY,
      TYPE_MAP,
      TYPE_STRUCT,
      TYPE_UNION
    ].freeze

    TYPE_NAME = {
      TYPE_VOID => "Void",
      TYPE_SCALAR => "Scalar",
      TYPE_BOOLEAN => "Boolean",
      TYPE_FLOAT => "Float",
      TYPE_STRING => "String",
      TYPE_BYTES => "Bytes",
      TYPE_ARRAY => "Array",
      TYPE_MAP => "Map",
      TYPE_STRUCT => "Struct",
      TYPE_UNION => "Union"
    }.freeze

    SIMPLE_PRIMITIVES = {
      void: TYPE_VOID,
      uint8: TYPE_SCALAR,
      uint16: TYPE_SCALAR,
      uint32: TYPE_SCALAR,
      uint64: TYPE_SCALAR,
      int8: TYPE_SCALAR,
      int16: TYPE_SCALAR,
      int32: TYPE_SCALAR,
      int64: TYPE_SCALAR,
      bool: TYPE_BOOLEAN,
      float32: TYPE_FLOAT,
      float64: TYPE_FLOAT,
      string: TYPE_STRING,
      bytes: TYPE_BYTES
    }.freeze

    def self.read_type(io)
      b = io.read(1).getbyte(0)
      decoded = b & 0xF
      raise UnknownTypeError, format("Unknown type 0x%02x", b) unless ALL_PRIMITIVES.include? decoded

      [decoded, b]
    end
  end
end
