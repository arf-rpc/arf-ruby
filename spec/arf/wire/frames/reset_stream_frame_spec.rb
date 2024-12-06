# frozen_string_literal: true

RSpec.describe Arf::Wire::ResetStreamFrame do
  it_behaves_like "a frame"

  let(:rt_data) do
    described_class.new.tap do |f|
      f.error_code = 10
      f.stream_id = random_stream_id
    end
  end
end
