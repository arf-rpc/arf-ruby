# frozen_string_literal: true

RSpec.describe Arf::Wire::GoAwayFrame do
  it_behaves_like "a frame"

  let(:rt_data) do
    described_class.new.tap do |f|
      f.last_stream_id = random_stream_id
      f.error_code = 0
      f.additional_data = SecureRandom.bytes(8)
    end
  end

  it "rejects frames with invalid size" do
    fr = Arf::Wire::Frame.new.tap do |f|
      f.stream_id = 0
      f.frame_kind = :go_away
      f.flags = 0
      f.length = 1
      f.payload = StringIO.new("\x01")
    end

    expect { described_class.new(fr) }.to raise_error(Arf::Wire::InvalidFrameLengthError)
  end
end
