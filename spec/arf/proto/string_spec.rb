# frozen_string_literal: true

RSpec.describe "Arf::Proto::String" do
  subject { Arf::Proto }
  let(:str) { "こんにちは、arf！" }
  let(:encoded_string) do
    [0x04, 0x18, 0xe3, 0x81, 0x93, 0xe3, 0x82, 0x93, 0xe3, 0x81, 0xab, 0xe3, 0x81, 0xa1, 0xe3, 0x81, 0xaf, 0xe3, 0x80,
     0x81, 0x61, 0x72, 0x66, 0xef, 0xbc, 0x81]
  end

  it "encodes empty" do
    buf = StringIO.new(subject.encode_string(""))
    buf.rewind
    expect(buf.readbyte).to eq 0x14
  end

  it "encodes value" do
    buf = StringIO.new(subject.encode_string(str))
    buf.rewind
    expect(buf.read.unpack("C*")).to eq encoded_string
  end

  it "decodes value" do
    buf = StringIO.new(encoded_string.pack("C*"))
    buf.rewind
    expect(subject.decode_string(buf.readbyte, buf)).to eq str
  end
end
