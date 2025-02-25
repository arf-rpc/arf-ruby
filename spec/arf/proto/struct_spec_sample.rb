# frozen_string_literal: true

class SampleStruct < Arf::RPC::Struct
  arf_struct_id "org.example.test/SampleStruct"
  field 0,      :a, :uint8
  field 1,      :b, :uint16
  field 2,      :c, :uint32
  field 3,      :d, :uint64
  field 4,      :e, :int8
  field 5,      :f, :int16
  field 6,      :g, :int32
  field 7,      :h, :int64
  field 8,      :i, :float32
  field 9,      :j, :float64
  field 10,     :k, :bool
  field 11,     :l, MapType[:string, :string]
  field 12,     :m, :string
  field 13,     :n, :bytes
  field 14,     :o, ArrayType[:string]
  field 15,     :p, :string, optional: true
  field 16,     :q, :bool, optional: true
  field 17,     :r, "SubStruct"
  field 18,     :w, MapType[:string, "SubStruct"].bind(self)
  field 19,     :x, ArrayType["SubStruct"].bind(self)

  class SubStruct < Arf::RPC::Struct
    arf_struct_id "org.example.test/SubStruct"
    field 0, :a, :string
  end
end
