# frozen_string_literal: true

RSpec.describe "Arf::Proto::Array" do
  subject { Arf::Proto }

  it "encodes empty" do
    expect(subject.encode([])).to eq "\x16"
  end

  it "encodes non-empty" do
    buf = subject.encode([1, 2, 3]).unpack("C*")
    expect(buf).to eq [0x06, 0x03, 0x01, 0x01, 0x01, 0x02, 0x01, 0x03]
  end

  it "decodes value" do
    buf = StringIO.new(subject.encode([1, 2, 3]))
    buf.rewind
    expect(subject.decode_array(buf.readbyte, buf)).to eq [1, 2, 3]
  end

  it "decodes empty" do
    buf = StringIO.new(subject.encode([]))
    buf.rewind
    expect(subject.decode_array(buf.readbyte, buf)).to eq []
  end
end
