# frozen_string_literal: true

RSpec.shared_examples "a peer" do |compression_value|
  let(:compression) { compression_value || :none }

  def dispatch_config
    compr = compression
    dispatch_frame Arf::Wire::ConfigurationFrame do |fr|
      case compr
      when :brotli
        fr.compression_brotli!
      when :gzip
        fr.compression_gzip!
      end
    end
  end

  def assert_config_response
    compr = compression
    expect(subject).to send_frame(Arf::Wire::ConfigurationFrame) do |fr|
      expect(fr).to be_ack
      case compr
      when :brotli
        expect(fr).to be_compression_brotli
      when :gzip
        expect(fr).to be_compression_gzip
      end
    end
  end

  it "responds with GOAWAY in case the connection is configured twice" do
    assert_config_response
    expect(subject).to send_frame(Arf::Wire::GoAwayFrame) do |fr|
      expect(fr.error_code).to eq Arf::Wire::ERROR_CODE_PROTOCOL_ERROR
    end

    expect(subject).to receive(:close_connection_after_writing)

    dispatch_config
    dispatch_config
  end

  it "resets a stream receiving data without a prior MAKE_STREAM" do
    assert_config_response
    dispatch_config

    expect(subject).to send_frame(Arf::Wire::ResetStreamFrame) do |fr|
      expect(fr.stream_id).to eq 10
      expect(fr.error_code).to eq Arf::Wire::ERROR_CODE_PROTOCOL_ERROR
    end

    dispatch_frame Arf::Wire::DataFrame do |fr|
      fr.stream_id = 10
      fr.payload = "Hello!"
    end
  end

  it "echoes back PING frames without a set ack flag" do
    assert_config_response
    dispatch_config

    ping_data = StringIO.new(SecureRandom.bytes(8))

    expect(subject).to send_frame(Arf::Wire::PingFrame) do |fr|
      expect(fr).to be_ack
      expect(fr.payload.string.force_encoding("UTF-8")).to eq ping_data.string.force_encoding("UTF-8")
    end

    dispatch_frame Arf::Wire::PingFrame do |fr|
      fr.payload = ping_data
    end
  end

  it "does nothing when receiving a PING frame with a set ack flag" do
    assert_config_response
    dispatch_config

    ping_data = StringIO.new(SecureRandom.bytes(8))

    dispatch_frame Arf::Wire::PingFrame do |fr|
      fr.payload = ping_data
      fr.ack!
    end
  end

  it "enqueues DATA frames" do
    assert_config_response
    dispatch_config

    dispatch_frame Arf::Wire::MakeStreamFrame do |fr|
      fr.stream_id = 1
    end

    expect(subject.fetch_stream(1)).not_to be_nil

    dispatch_frame Arf::Wire::DataFrame do |fr|
      fr.stream_id = 1
      fr.end_data!
      fr.payload = "Hello"
    end

    str = subject.fetch_stream(1)
    expect(str.read.string).to eq "Hello"
  end

  it "resets a stream when RESET_STREAM is received" do
    assert_config_response
    dispatch_config

    dispatch_frame Arf::Wire::MakeStreamFrame do |fr|
      fr.stream_id = 1
    end

    expect(subject.fetch_stream(1)).not_to be_nil

    dispatch_frame Arf::Wire::ResetStreamFrame do |fr|
      fr.stream_id = 1
      fr.error_code = Arf::Wire::ERROR_CODE_NO_ERROR
    end

    str = subject.fetch_stream(1)
    expect(str.state).to be_closed
  end

  it "cancels streams when receiving a GOAWAY" do
    assert_config_response
    dispatch_config

    dispatch_frame Arf::Wire::MakeStreamFrame do |fr|
      fr.stream_id = 1
    end

    expect(subject.fetch_stream(1)).not_to be_nil

    expect(subject).to send_frame(Arf::Wire::ResetStreamFrame) do |fr|
      expect(fr.stream_id).to eq 1
    end
    expect(subject).to receive(:close_connection_after_writing)
    dispatch_frame Arf::Wire::GoAwayFrame do |fr|
      fr.error_code = Arf::Wire::ERROR_CODE_NO_ERROR
      fr.last_stream_id = 0
    end
  end
end
