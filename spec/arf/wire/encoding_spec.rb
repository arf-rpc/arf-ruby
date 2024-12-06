# frozen_string_literal: true

RSpec.describe "Arf::Wire::Encoding" do
  context "#data_frames_from_buffer" do
    context "with end_stream" do
      it "returns a single frame if it fits MAX_PAYLOAD" do
        data = 1.upto(10).to_a.pack("C*")
        bufs = Arf::Wire.data_frames_from_buffer(1, data, end_stream: true)
        expect(bufs.length).to eq 1
        buf = bufs.first
        expect(buf).to be_end_data
        expect(buf).to be_end_stream
        expect(buf.stream_id).to eq 1
        expect(buf.payload).to eq data
      end

      it "returns multiple frames if it is longer than MAX_PAYLOAD" do
        data = 1.upto(Arf::Wire::MAX_PAYLOAD + 1).to_a.pack("C*")
        bufs = Arf::Wire.data_frames_from_buffer(1, data, end_stream: true)
        expect(bufs.length).to eq 2
        buf = bufs.first
        expect(buf).not_to be_end_data
        expect(buf).to be_end_stream
        expect(buf.stream_id).to eq 1
        expect(buf.payload).to eq data[...-1]

        buf = bufs.last
        expect(buf).to be_end_data
        expect(buf).to be_end_stream
        expect(buf.stream_id).to eq 1
        expect(buf.payload).to eq data[-1...]
      end
    end

    context "without end_stream" do
      it "returns a single frame if it fits MAX_PAYLOAD" do
        data = 1.upto(10).to_a.pack("C*")
        bufs = Arf::Wire.data_frames_from_buffer(1, data, end_stream: false)
        expect(bufs.length).to eq 1
        buf = bufs.first
        expect(buf).to be_end_data
        expect(buf).not_to be_end_stream
        expect(buf.stream_id).to eq 1
        expect(buf.payload).to eq data
      end

      it "returns multiple frames if it is longer than MAX_PAYLOAD" do
        data = 1.upto(Arf::Wire::MAX_PAYLOAD + 1).to_a.pack("C*")
        bufs = Arf::Wire.data_frames_from_buffer(1, data, end_stream: false)
        expect(bufs.length).to eq 2
        buf = bufs.first
        expect(buf).not_to be_end_data
        expect(buf).not_to be_end_stream
        expect(buf.stream_id).to eq 1
        expect(buf.payload).to eq data[...-1]

        buf = bufs.last
        expect(buf).to be_end_data
        expect(buf).not_to be_end_stream
        expect(buf.stream_id).to eq 1
        expect(buf.payload).to eq data[-1...]
      end
    end
  end
end
