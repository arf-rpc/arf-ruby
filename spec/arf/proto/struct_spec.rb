# frozen_string_literal: true

require_relative "struct_spec_sample"

RSpec.describe "Arf::Proto::Struct" do
  subject { Arf::Proto }
  before do
    Arf::Proto::Registry.reset!
    Arf::Proto::Registry.register! SampleStruct
    Arf::Proto::Registry.register! SampleStruct::SubStruct
  end

  it "encodes and decodes a struct" do
    i = SampleStruct.new(
      a: 0,
      b: 1,
      c: 2,
      d: 3,
      e: 4,
      f: 5,
      g: 6,
      h: 7,
      i: 8,
      j: 9,
      k: true,
      l: { hello: "arf!" },
      m: "Sample String",
      n: [1, 2, 3],
      o: %w[hello world],
      p: "ptr string",
      r: { a: "SubStruct value" },
      s: { v: 64 },
      w: { test: { a: "substruct in map" } },
      x: [{ a: "substruct in array 1" }, { a: "substruct in array 2" }]
    )

    raw_data = subject.encode(i)
    data = StringIO.new(raw_data)
    decoded = subject.decode(data)
    expect(decoded).to eq i
  end
end
