# frozen_string_literal: true

RSpec.describe "Arf::Proto::Map" do
  subject { Arf::Proto }
  let(:the_map) do
    {
      "en" => "Hello, arf!",
      "ja" => "こんにちは、arf！",
      "it" => "Ciao, arf!"
    }
  end

  it "encode/decode" do
    data = StringIO.new(subject.encode(the_map))
    data.rewind
    expect(subject.decode(data)).to eq the_map
  end
end
