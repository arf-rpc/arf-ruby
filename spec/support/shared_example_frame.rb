# frozen_string_literal: true

RSpec.shared_examples "a frame" do
  context "flags" do
    context "decoding" do
      set_flags = {}
      described_class.flags.each_pair do |k, v|
        flags = set_flags.merge(k => v)
        set_flags = flags
        it "decodes #{flags.inspect}" do
          value = 0x00
          flags.each_value { |val| value |= (0x01 << val) }
          fr = Arf::Wire::Frame.new.tap { _1.flags = value }
          inst = described_class.new
          inst.decode_flags(fr)
          flags.each_key do |key|
            expect(inst.send("#{key}?")).to eq true
          end
        end
      end
    end

    context "encoding" do
      set_flags = {}
      described_class.flags.each_pair do |k, v|
        flags = set_flags.merge(k => v)
        set_flags = flags
        it "encodes #{flags.inspect}" do
          expected = 0x00
          flags.each_value { |val| expected |= (0x01 << val) }
          inst = described_class.new
          flags.each_key { inst.send("#{_1}!") }
          expect(inst.encode_flags).to eq expected
        end
      end
    end
  end

  context "round-trip" do
    it "encodes and decodes from a frame without compression" do
      data = rt_data.to_frame.bytes(:none)
      fr = Arf::Wire::Frame.from_io(StringIO.new(data))
      fr.decompress(:none)
      decoded = described_class.new(fr)
      expect(decoded).to eq decoded
    end

    %i[gzip brotli].each do |comp|
      it "encodes and decodes from a frame with #{comp} compression" do
        data = rt_data.to_frame.bytes(comp)
        fr = Arf::Wire::Frame.from_io(StringIO.new(data))
        fr.decompress(comp)
        decoded = described_class.new(fr)
        expect(decoded).to eq decoded
      end
    end
  end
end
