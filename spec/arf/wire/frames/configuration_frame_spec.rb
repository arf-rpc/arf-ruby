# frozen_string_literal: true

RSpec.describe Arf::Wire::HelloFrame do
  it_behaves_like "a frame"

  let(:rt_data) do
    described_class.new.tap do |f|
      f.compression_gzip!
      f.ack!
      f.max_concurrent_streams = 10
    end
  end

  it "rejects frames with invalid size" do
    fr = Arf::Wire::Frame.new.tap do |f|
      f.stream_id = 0
      f.frame_kind = :hello
      f.flags = 0
      f.length = 1
      f.payload = StringIO.new("\x01")
    end

    expect { described_class.new(fr) }.to raise_error(Arf::Wire::InvalidFrameLengthError)
  end

  it "rejects frames without ack flag and max concurrent streams" do
    fr = Arf::Wire::Frame.new.tap do |f|
      f.stream_id = 0
      f.frame_kind = :hello
      f.flags = 0
      f.length = 4
      f.payload = StringIO.new("\x00\x00\x00\x01")
    end

    expect { described_class.new(fr) }.to raise_error(Arf::Wire::InvalidFrameError)
      .with_message(/non-ack/)
  end
end
