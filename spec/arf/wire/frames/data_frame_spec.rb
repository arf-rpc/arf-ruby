# frozen_string_literal: true

RSpec.describe Arf::Wire::DataFrame do
  it_behaves_like "a frame"

  let(:rt_data) do
    described_class.new.tap do |f|
      f.payload = SecureRandom.bytes(32)
      f.stream_id = random_stream_id
    end
  end
end
