# frozen_string_literal: true

RSpec.describe Arf::Wire::Frame do
  it "decodes a frame without payload" do
    data = StringIO.new([
      0x61, 0x72, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ].pack("C*"))
    decoded = described_class.from_io(data)
    expect(decoded.stream_id).to be_zero
    expect(decoded.flags).to be_zero
    expect(decoded.frame_kind).to eq :hello
    expect(decoded.length).to be_zero
    expect(decoded.payload).to be_nil
  end

  it "decodes a frame with payload" do
    data = StringIO.new([
      0x61, 0x72, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00
    ].pack("C*"))
    decoded = described_class.from_io(data)
    expect(decoded.stream_id).to be_zero
    expect(decoded.flags).to eq 0x04
    expect(decoded.frame_kind).to eq :hello
    expect(decoded.length).to eq 4
    expect(decoded.payload.string).to eq "\x00\x00\x00\x00"
  end
end
