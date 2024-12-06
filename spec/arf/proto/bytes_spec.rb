# frozen_string_literal: true

RSpec.describe "Arf::Proto::Bytes" do
  subject { Arf::Proto }

  it "encodes empty" do
    buf = StringIO.new(subject.encode_bytes([]))
    buf.rewind
    expect(buf.string.unpack("C*")).to eq [0x15]
  end

  it "encodes non-empty" do
    buf = StringIO.new(subject.encode_bytes("test"))
    buf.rewind
    expect(buf.string.unpack("C*")).to eq [0x5, 0x4, 0x74, 0x65, 0x73, 0x74]
  end

  it "decodes empty" do
    buf = StringIO.new(subject.encode_bytes([]))
    buf.rewind
    expect(subject.decode_bytes(buf.readbyte, buf)).to eq ""
  end

  it "decodes non-empty" do
    buf = StringIO.new(subject.encode_bytes("test"))
    buf.rewind
    expect(subject.decode_bytes(buf.readbyte, buf)).to eq "test"
  end
end
