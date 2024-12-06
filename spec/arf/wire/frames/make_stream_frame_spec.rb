# frozen_string_literal: true

RSpec.describe Arf::Wire::MakeStreamFrame do
  it_behaves_like "a frame"

  let(:rt_data) do
    described_class.new.tap do |f|
      f.stream_id = random_stream_id
    end
  end

  it "rejects frames with invalid size" do
    fr = Arf::Wire::Frame.new.tap do |f|
      f.stream_id = 1
      f.frame_kind = :make_stream
      f.flags = 0
      f.length = 1
      f.payload = StringIO.new("\x01")
    end

    expect { described_class.new(fr) }.to raise_error(Arf::Wire::InvalidFrameLengthError)
  end
end
