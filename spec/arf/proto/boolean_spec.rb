# frozen_string_literal: true

RSpec.describe "Arf::Proto::Boolean" do
  subject { Arf::Proto }
  let(:buf) { StringIO.new }

  it "encodes true" do
    expect(subject.encode_boolean(true).unpack1("C*")).to eq 0x12
  end

  it "encodes false" do
    expect(subject.encode_boolean(false).unpack1("C*")).to eq 0x2
  end

  it "encodes and decodes true" do
    buf = StringIO.new(subject.encode_boolean(true))
    buf.rewind
    expect(subject.decode_boolean(buf.readbyte, buf)).to eq true
  end

  it "encodes and decodes false" do
    buf = StringIO.new(subject.encode_boolean(false))
    buf.rewind
    expect(subject.decode_boolean(buf.readbyte, buf)).to eq false
  end
end
