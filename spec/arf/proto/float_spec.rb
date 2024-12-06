# frozen_string_literal: true

RSpec.describe "Arf::Proto::Float" do
  subject { Arf::Proto }

  context "float32" do
    it "encodes zero" do
      buf = StringIO.new(subject.encode_float32(0))
      expect(buf.string.unpack("C*")).to eq [0x23]
    end

    it "encodes non-zero" do
      number = [Math::PI].pack("f").unpack1("f")
      buf = StringIO.new(subject.encode_float32(number))
      expect(buf.string.unpack("C*")).to eq [0x3, 0x40, 0x49, 0xf, 0xdb]
    end

    it "decodes zero" do
      buf = StringIO.new(subject.encode_float32(0))
      buf.rewind
      expect(subject.decode_float(buf.readbyte, buf)).to be_zero
    end

    it "decodes non-zero" do
      number = [Math::PI].pack("f").unpack1("f")
      buf = StringIO.new(subject.encode_float32(number))
      buf.rewind
      expect(subject.decode_float(buf.readbyte, buf)).to eq number
    end
  end

  context "float64" do
    it "encodes zero" do
      buf = StringIO.new(subject.encode_float64(0))
      expect(buf.string.unpack("C*")).to eq [0x33]
    end

    it "encodes non-zero" do
      number = [Math::PI].pack("d").unpack1("d")
      buf = StringIO.new(subject.encode_float64(number))
      expect(buf.string.unpack("C*")).to eq [0x13, 0x40, 0x9, 0x21, 0xfb, 0x54, 0x44, 0x2d, 0x18]
    end

    it "decodes zero" do
      buf = StringIO.new(subject.encode_float64(0))
      buf.rewind
      expect(subject.decode_float(buf.readbyte, buf)).to be_zero
    end

    it "decodes non-zero" do
      number = [Math::PI].pack("f").unpack1("f")
      buf = StringIO.new(subject.encode_float64(number))
      buf.rewind
      expect(subject.decode_float(buf.readbyte, buf)).to eq number
    end
  end
end
