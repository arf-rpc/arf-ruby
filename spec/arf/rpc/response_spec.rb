# frozen_string_literal: true

RSpec.describe Arf::RPC::Response do
  it "initializes from kwargs" do
    i = described_class.new(
      streaming: true,
      status: 0,
      params: [1, 2, "hello"],
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )
    expect(i).to be_streaming
    expect(i.status).to eq :ok
    expect(i.params).to eq [1, 2, "hello"]
    expect(i.metadata.get("param-1")).to eq "true"
    expect(i.metadata.get("param-2")).to eq "false"
  end

  it "encodes and decodes data" do
    i = described_class.new(
      streaming: true,
      status: :ok,
      params: [1, 2, "hello"],
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )
    data = i.encode

    d = described_class.new
    d.decode(StringIO.new(data))
    expect(d).to be_streaming
    expect(d.status).to eq :ok
    expect(d.params).to eq [1, 2, "hello"]
    expect(d.metadata.get("param-1")).to eq "true"
    expect(d.metadata.get("param-2")).to eq "false"
  end

  it "encodes and decodes as a message" do
    i = described_class.new(
      streaming: true,
      status: :ok,
      params: [1, 2, "hello"],
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )

    data = Arf::RPC::BaseMessage.encode(i)
    d = Arf::RPC::BaseMessage.initialize_from(StringIO.new(data))
    expect(d).to be_streaming
    expect(d.status).to eq :ok
    expect(d.params).to eq [1, 2, "hello"]
    expect(d.metadata.get("param-1")).to eq "true"
    expect(d.metadata.get("param-2")).to eq "false"
  end
end
