# frozen_string_literal: true

RSpec.describe "Arf::Proto::Scalar" do
  subject { Arf::Proto }

  context "zero" do
    it "encodes as a signed value" do
      buf = StringIO.new(subject.encode_scalar(0, signed: true))
      buf.rewind
      expect(buf.readbyte).to eq 0x31

      buf.rewind
      d, b = subject.read_type(buf)
      expect(d).to eq Arf::Proto::TYPE_SCALAR
      expect(b).to eq 0x31

      buf.rewind
      v = subject.decode_scalar(b, buf)
      expect(v).to be_zero
    end

    it "encodes as an unsigned value" do
      buf = StringIO.new(subject.encode_scalar(0, signed: false))
      buf.rewind
      expect(buf.readbyte).to eq 0x21

      buf.rewind
      d, b = subject.read_type(buf)
      expect(d).to eq Arf::Proto::TYPE_SCALAR
      expect(b).to eq 0x21

      buf.rewind
      v = subject.decode_scalar(b, buf)
      expect(v).to be_zero
    end
  end

  context "ten" do
    it "encodes as a signed value" do
      buf = StringIO.new(subject.encode_scalar(-10, signed: true))
      buf.rewind
      expect(buf.readbyte).to eq 0x51

      buf.rewind
      d, b = subject.read_type(buf)
      expect(d).to eq Arf::Proto::TYPE_SCALAR
      expect(b).to eq 0x51

      buf.rewind
      v = subject.decode_scalar(buf.readbyte, buf)
      expect(v).to eq(-10)
    end

    it "encodes as an unsigned value" do
      buf = StringIO.new(subject.encode_scalar(10, signed: false))
      buf.rewind
      expect(buf.readbyte).to eq 0x1
      expect(buf.readbyte).to eq 0xa

      buf.rewind
      d, b = subject.read_type(buf)
      expect(d).to eq Arf::Proto::TYPE_SCALAR
      expect(b).to eq 0x1

      buf.rewind
      v = subject.decode_scalar(buf.readbyte, buf)
      expect(v).to eq 10
    end
  end

  context "unsigned integer" do
    0.upto(1024).each do |i|
      it "encodes and decodes #{i}" do
        buffer = StringIO.new(subject.encode_scalar(i))
        buffer.rewind
        expect(subject.decode_scalar(buffer.readbyte, buffer)).to eq i
      end
    end
  end

  context "signed integer" do
    -1024.upto(1024).each do |i|
      it "encodes and decodes #{i}" do
        buffer = StringIO.new(subject.encode_scalar(i, signed: true))
        buffer.rewind
        expect(subject.decode_scalar(buffer.readbyte, buffer)).to eq i
      end
    end
  end
end
