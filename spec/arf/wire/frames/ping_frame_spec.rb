# frozen_string_literal: true

RSpec.describe Arf::Wire::PingFrame do
  it_behaves_like "a frame"

  let(:rt_data) do
    described_class.new.tap do |f|
      f.payload = SecureRandom.bytes(8)
      f.ack!
    end
  end
end
