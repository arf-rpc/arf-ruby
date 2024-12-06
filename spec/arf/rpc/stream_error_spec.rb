# frozen_string_literal: true

RSpec.describe Arf::RPC::StreamError do
  it "initializes from kwargs" do
    i = described_class.new(
      status: 0,
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )
    expect(i.status).to eq :ok
    expect(i.metadata.get("param-1")).to eq "true"
    expect(i.metadata.get("param-2")).to eq "false"
  end

  it "encodes and decodes data" do
    i = described_class.new(
      status: :ok,
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )
    data = i.encode

    d = described_class.new
    d.decode(StringIO.new(data))
    expect(d.status).to eq :ok
    expect(d.metadata.get("param-1")).to eq "true"
    expect(d.metadata.get("param-2")).to eq "false"
  end

  it "encodes and decodes as a message" do
    i = described_class.new(
      status: :ok,
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )
    data = Arf::RPC::BaseMessage.encode(i)
    d = Arf::RPC::BaseMessage.initialize_from(StringIO.new(data))
    expect(d.status).to eq :ok
    expect(d.metadata.get("param-1")).to eq "true"
    expect(d.metadata.get("param-2")).to eq "false"
  end
end
