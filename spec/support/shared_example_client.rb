# frozen_string_literal: true

RSpec.shared_examples "a client" do |compression_value|
  let(:compression) { compression_value }
  before do
    allow_any_instance_of(Arf::Configuration).to receive(:client_compression)
      .and_return(compression_value)
  end

  subject { Arf.connect("127.0.0.1", 2730) }

  it "connects and disconnects" do
    subject.wait_configuration
    expect(subject.instance_variable_get(:@compression)).to eq compression
    subject.close
  end

  it "sends ping messages" do
    subject.ping
    subject.wait_pong
    subject.close
  end

  it "creates new streams" do
    str = subject.new_stream
    str.write_data("Hello!")
    q = attach_dummy_handler(str)
    peer = get_server_peers(@server).last
    stream = wait_for_stream(peer)
    wait_for_read(stream)
    expect(stream.read.string).to eq "Hello!"
    stream.write_data("Ciao!")
    expect(q.pop.string).to eq "Ciao!"
    str.reset(Arf::Wire::ERROR_CODE_CANCEL)
    subject.close
  end

  it "responds to pings" do
    subject.new_stream
    peer = get_server_peers(@server).last
    peer.ping
    peer.wait_pong
  end

  it "handles go away frames" do
    subject.new_stream
    peer = get_server_peers(@server).last
    peer.go_away!(Arf::Wire::ERROR_CODE_CANCEL, terminate: true)
  end

  it "handles stream resets" do
    str = subject.new_stream
    peer = get_server_peers(@server).last
    stream = wait_for_stream(peer)
    stream.reset(Arf::Wire::ERROR_CODE_CANCEL)
    wait_for_reset(str)
    expect(str.state).to be_closed
  end
end
