# frozen_string_literal: true

RSpec.describe Arf::Server do
  before do
    subject.run
  end

  after do
    subject.shutdown
    RPCHelpers.reset_service_state!
  end

  let(:client) { Arf.connect("127.0.0.1", 2730) }
  let(:sample) { RPCHelpers::SampleClient.new(client) }

  it "rejects a request if it does not begin with a request" do
    str = client.new_stream
    str.write_data(Arf::RPC::BaseMessage.encode(Arf::RPC::StartStream.new))
    msg = Arf::RPC::BaseMessage.initialize_from(str.read_blocking)
    expect(msg.status).to eq :failed_precondition
  end

  it "handles requests with no inputs and no outputs" do
    resp = sample.no_input__no_output__no_input_stream__no_output_stream
    expect(resp.metadata).to have_key "arf-request-id"
    expect(resp.params).to be nil
  end

  it "handles requests with no input and a single output" do
    resp = sample.no_input__output__no_input_stream__no_output_stream
    expect(resp.metadata).to have_key "arf-request-id"
    expect(resp.params).to eq "Hello!"
  end

  it "handles requests with no input, no output, and a streaming output" do
    resp = sample.no_input__no_output__no_input_stream__output_stream
    expect(resp.metadata).to have_key "arf-request-id"
    expect(resp.recv).to eq "Hello!"
    expect(resp.recv).to eq "World!"
  end

  it "handles requests with no input, no output, and a streaming input" do
    resp = sample.no_input__no_output__input_stream__no_output_stream
    resp.push("Hello!")
    resp.push("World!")
    wait_for_received_items(len: 2)
    expect(RPCHelpers.service_state.received_items).to eq ["Hello!", "World!"]
  end

  it "handles requests with no input, streaming input and output" do
    resp = sample.no_input__no_output__input_stream__output_stream
    resp.push("C1")
    resp.push("C2")
    wait_for_received_items(len: 2)
    expect(RPCHelpers.service_state.received_items).to eq %w[C1 C2]

    expect(resp.recv).to eq "S1"
    expect(resp.recv).to eq "S2"
  end

  it "handles request with no input, output, and a streaming input" do
    resp = sample.no_input__output__input_stream__no_output_stream
    resp.push("C1")
    resp.push("C2")
    wait_for_received_items(len: 2)
    expect(RPCHelpers.service_state.received_items).to eq %w[C1 C2]
    expect(resp.params).to eq "Hello!"
  end

  it "handles request with no input, output, and a streaming input and output" do
    resp = sample.no_input__output__input_stream__output_stream
    resp.push("C1")
    resp.push("C2")
    wait_for_received_items(len: 2)
    expect(RPCHelpers.service_state.received_items).to eq %w[C1 C2]
    expect(resp.params).to eq "Hello!"
    expect(resp.recv).to eq "S1"
    expect(resp.recv).to eq "S2"
  end

  it "handles request with input, no output, no streaming" do
    sample.input__no_output__no_input_stream__no_output_stream("C1")
    wait_for_received_items(len: 1)
    expect(RPCHelpers.service_state.received_items).to eq ["C1"]
  end

  it "handles request with input, no output, and output stream" do
    resp = sample.input__no_output__no_input_stream__output_stream("C1")
    expect(resp.recv).to eq "C1"
  end

  it "handles request with input, no output, and input stream" do
    resp = sample.input__no_output__input_stream__no_output_stream("C1")
    resp.push("C2")
    resp.push("C3")
    wait_for_received_items(len: 3)
    expect(RPCHelpers.service_state.received_items).to eq %w[C1 C2 C3]
  end

  it "handles request with input, no output and input and output streams" do
    resp = sample.input__no_output__input_stream__output_stream("C1")
    resp.push("C2")
    resp.push("C3")
    wait_for_received_items(len: 3)
    expect(RPCHelpers.service_state.received_items).to eq %w[C1 C2 C3]
    expect(resp.recv).to eq "S1"
    expect(resp.recv).to eq "S2"
  end

  it "handles request with input, output and no streams" do
    resp = sample.input__output__no_input_stream__no_output_stream("C1")
    expect(resp.params).to eq "C1"
  end

  it "handles request with input, output and output stream" do
    resp = sample.input__output__no_input_stream__output_stream("C1")
    expect(resp.params).to eq "C1"
    expect(resp.recv).to eq "S1"
    expect(resp.recv).to eq "S2"
  end

  it "handles request with input, output and input stream" do
    resp = sample.input__output__input_stream__no_output_stream("C1")
    resp.push("C2")
    resp.push("C3")
    wait_for_received_items(len: 2)
    expect(RPCHelpers.service_state.received_items).to eq %w[C2 C3]
    expect(resp.params).to eq "C1"
  end

  it "handles request with input, output, input stream, and output stream" do
    resp = sample.input__output__input_stream__output_stream("C1")
    resp.push("C2")
    resp.push("C3")
    resp.close_send
    wait_for_received_items(len: 2)
    expect(RPCHelpers.service_state.received_items).to eq %w[C2 C3]
    expect(resp.params).to eq "C1"
    expect(resp.recv).to eq "S1"
    expect(resp.recv).to eq "S2"
  end
end
