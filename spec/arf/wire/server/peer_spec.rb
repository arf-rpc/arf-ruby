# frozen_string_literal: true

RSpec.describe Arf::Wire::Server::Peer do
  let(:server) { double(:server) }
  let(:id) { 1 }

  subject { described_class.new(server) }

  before do
    allow(server).to receive(:handle_stream)
    allow(server).to receive(:register_peer)
  end

  context "without configuration" do
    it "responds data frames with GOAWAY" do
      expect(subject).to send_frame(Arf::Wire::GoAwayFrame) do |fr|
        expect(fr.error_code).to eq Arf::Wire::ERROR_CODE_PROTOCOL_ERROR
      end
      expect(subject).to receive(:close_connection_after_writing)

      dispatch_frame Arf::Wire::DataFrame do |fr|
        fr.stream_id = 10
        fr.payload = "henlo"
      end
    end

    it "terminates the connection when receiving an GOAWAY" do
      expect(subject).to send_frame(Arf::Wire::GoAwayFrame) do |fr|
        expect(fr.error_code).to eq Arf::Wire::ERROR_CODE_PROTOCOL_ERROR
      end
      expect(subject).to receive(:close_connection_after_writing)

      dispatch_frame Arf::Wire::GoAwayFrame do |fr|
        fr.last_stream_id = 0
        fr.error_code = 0
      end
    end

    it "responds ill-encoded frames with GOAWAY" do
      fr = Arf::Wire::GoAwayFrame.new do |f|
        f.last_stream_id = 0
        f.error_code = 0
        f.additional_data = [
          0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
        ].pack("C*")
      end
      f = fr.to_frame
      f.frame_kind = :configuration

      expect(subject).to send_frame(Arf::Wire::GoAwayFrame) do |frame|
        expect(frame.error_code).to eq Arf::Wire::ERROR_CODE_PROTOCOL_ERROR
      end
      expect(subject).to receive(:close_connection_after_writing)

      subject.recv(f.bytes(@compression || :none))
    end
  end

  context "with configuration" do
    context "without compression" do
      it_behaves_like "a peer"
    end

    context "with gzip compression" do
      it_behaves_like "a peer", :gzip
    end

    context "with brotli compression" do
      it_behaves_like "a peer", :brotli
    end
  end
end
