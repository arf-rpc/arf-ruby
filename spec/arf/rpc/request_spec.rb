# frozen_string_literal: true

RSpec.describe Arf::RPC::Request do
  it "initializes from kwargs" do
    i = described_class.new(
      streaming: true,
      service: "test-service",
      method: "test-method",
      params: [1, 2, "hello"],
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )
    expect(i).to be_streaming
    expect(i.service).to eq "test-service"
    expect(i.method).to eq "test-method"
    expect(i.params).to eq [1, 2, "hello"]
    expect(i.metadata.get("param-1")).to eq "true"
    expect(i.metadata.get("param-2")).to eq "false"
  end

  it "encodes and decodes data" do
    e = described_class.new(
      streaming: true,
      service: "test-service",
      method: "test-method",
      params: [1, 2, "hello"],
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )

    data = e.encode
    d = described_class.new
    d.decode(StringIO.new(data))
    expect(d).to be_streaming
    expect(d.service).to eq "test-service"
    expect(d.method).to eq "test-method"
    expect(d.params).to eq [1, 2, "hello"]
    expect(d.metadata.get("param-1")).to eq "true"
    expect(d.metadata.get("param-2")).to eq "false"
  end

  it "encodes and decodes as a message" do
    e = described_class.new(
      streaming: true,
      service: "test-service",
      method: "test-method",
      params: [1, 2, "hello"],
      metadata: {
        "param-1" => "true",
        "param-2" => "false"
      }
    )
    data = Arf::RPC::BaseMessage.encode(e)
    d = Arf::RPC::BaseMessage.initialize_from(StringIO.new(data))
    expect(d).to be_streaming
    expect(d.service).to eq "test-service"
    expect(d.method).to eq "test-method"
    expect(d.params).to eq [1, 2, "hello"]
    expect(d.metadata.get("param-1")).to eq "true"
    expect(d.metadata.get("param-2")).to eq "false"
  end
end
