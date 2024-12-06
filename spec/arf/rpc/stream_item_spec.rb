# frozen_string_literal: true

RSpec.describe Arf::RPC::StreamItem do
  it "initializes from kwargs" do
    i = described_class.new(
      value: "test"
    )
    expect(i.value).to eq "test"
  end

  it "encodes and decodes data" do
    i = described_class.new(
      value: "test"
    )
    data = i.encode

    d = described_class.new
    d.decode(StringIO.new(data))
    expect(d.value).to eq "test"
  end

  it "encodes and decodes as a message" do
    i = described_class.new(
      value: "test"
    )
    data = Arf::RPC::BaseMessage.encode(i)
    d = Arf::RPC::BaseMessage.initialize_from(StringIO.new(data))
    expect(d.value).to eq "test"
  end
end
