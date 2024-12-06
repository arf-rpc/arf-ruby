# frozen_string_literal: true

RSpec.describe Arf::Wire::Stream do
  let(:id) { 1 }
  let(:driver) { double(:driver) }

  subject { described_class.new(id, driver) }

  context "open" do
    it "closes the connection receiving a reset" do
      subject.handle_reset_stream(Arf::Wire::ResetStreamFrame.new do |fr|
        fr.stream_id = id
        fr.error_code = Arf::Wire::ERROR_CODE_CANCEL
      end)

      expect(subject.state).to be_closed
      expect(subject.state.error).to be_a Arf::Wire::StreamResetError
    end

    it "enqueues data for reading" do
      data = SecureRandom.bytes(32)
      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = id
        fr.payload = data
        fr.end_data!
      end)
    end

    it "allows extra data to be sent when receiving data with END_DATA" do
      data_a = SecureRandom.bytes(32)
      data_b = SecureRandom.bytes(32)
      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = id
        fr.payload = data_a
      end)

      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = id
        fr.payload = data_b
        fr.end_data!
      end)

      expect(subject.read.string).to eq "#{data_a}#{data_b}".force_encoding("utf-8")
    end

    it "half-closes the stream receiving data with END_STREAM" do
      data = SecureRandom.bytes(32)
      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = id
        fr.payload = data
        fr.end_data!
        fr.end_stream!
      end)

      expect(subject.state).to be_remote_closed
    end

    it "issues a DataFrame when calling write_data" do
      data = SecureRandom.bytes(32)
      expect(driver).to receive(:dispatch) do |fr, _terminate|
        expect(fr).to be_a Arf::Wire::DataFrame
        expect(fr).to be_end_data
        expect(fr).not_to be_end_stream
        expect(fr.payload).to eq data.force_encoding("UTF-8")
      end

      subject.write_data(data)
    end

    it "half-closes the stream when calling write_data with END_STREAM" do
      data = SecureRandom.bytes(32)
      expect(driver).to receive(:dispatch) do |fr, _terminate|
        expect(fr).to be_a Arf::Wire::DataFrame
        expect(fr).to be_end_data
        expect(fr).to be_end_stream
        expect(fr.payload).to eq data.force_encoding("UTF-8")
      end

      subject.write_data(data, end_stream: true)
    end

    it "issues an empty DATA frame when calling close_local" do
      expect(driver).to receive(:dispatch) do |fr, _terminate|
        expect(fr).to be_a Arf::Wire::DataFrame
        expect(fr).to be_end_data
        expect(fr).to be_end_stream
        expect(fr.payload).to be_nil
      end

      subject.close_local
    end

    it "closes the connection when both sides are closed" do
      data = SecureRandom.bytes(32)
      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = id
        fr.payload = data
        fr.end_data!
        fr.end_stream!
      end)

      expect(subject.state.code).to eq :half_closed_remote

      expect(driver).to receive(:dispatch) do |fr, _terminate|
        expect(fr).to be_a Arf::Wire::DataFrame
        expect(fr).to be_end_data
        expect(fr).to be_end_stream
        expect(fr.payload).to be_nil
      end
      subject.close_local
      expect(subject.state).to be_closed
    end

    it "segments large data" do
      data = SecureRandom.bytes(Arf::Wire::MAX_PAYLOAD + 10)

      expect(driver).to receive(:dispatch).once.ordered do |fr, _terminate|
        expect(fr).to be_a Arf::Wire::DataFrame
        expect(fr).not_to be_end_data
        expect(fr).not_to be_end_stream
        expect(fr.payload).to eq data[...Arf::Wire::MAX_PAYLOAD]
      end

      expect(driver).to receive(:dispatch).once.ordered do |fr, _terminate|
        expect(fr).to be_a Arf::Wire::DataFrame
        expect(fr).to be_end_data
        expect(fr).not_to be_end_stream
        expect(fr.payload).to eq data[Arf::Wire::MAX_PAYLOAD...]
      end

      subject.write_data(data)
    end
  end

  context "closed" do
    before do
      expect(driver).to receive(:dispatch).with(kind_of(Arf::Wire::ResetStreamFrame))
      subject.reset(Arf::Wire::ERROR_CODE_CANCEL)
    end

    it "#write_data raises a ClosedStreamError" do
      expect { subject.write_data("hello") }.to raise_error(Arf::Wire::ClosedStreamError)
    end

    it "#close_local raises a ClosedStreamError" do
      expect { subject.close_local }.to raise_error(Arf::Wire::ClosedStreamError)
    end

    it "returns ErrorCodeStreamClosed upon receiving a reset" do
      expect(driver).to receive(:dispatch).with(kind_of(Arf::Wire::ResetStreamFrame)) do |fr|
        expect(fr.error_code).to eq Arf::Wire::ERROR_CODE_STREAM_CLOSED
      end

      subject.handle_reset_stream(Arf::Wire::ResetStreamFrame.new do |fr|
        fr.stream_id = 10
        fr.error_code = Arf::Wire::ERROR_CODE_CANCEL
      end)
    end

    it "returns ErrorCodeStreamClosed upon receiving data" do
      expect(driver).to receive(:dispatch).with(kind_of(Arf::Wire::ResetStreamFrame)) do |fr|
        expect(fr.error_code).to eq Arf::Wire::ERROR_CODE_STREAM_CLOSED
      end

      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = 10
        fr.payload = "hello"
      end)
    end
  end

  context "remote reset" do
    before do
      subject.handle_reset_stream(Arf::Wire::ResetStreamFrame.new do |fr|
        fr.stream_id =  1
        fr.error_code = Arf::Wire::ERROR_CODE_CANCEL
      end)
    end

    it "#write_data raises a StreamResetError" do
      expect { subject.write_data("hello") }.to raise_error(Arf::Wire::StreamResetError)
    end

    it "#read raises a StreamResetError" do
      expect { subject.read }.to raise_error(Arf::Wire::StreamResetError)
    end

    it "#close_local raises a StreamResetError" do
      expect { subject.close_local }.to raise_error(Arf::Wire::StreamResetError)
    end
  end

  context "half-closed remote" do
    before do
      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = 1
        fr.end_stream!
      end)
    end

    it "accepts incoming ResetStreamFrame" do
      subject.handle_reset_stream(Arf::Wire::ResetStreamFrame.new do |fr|
        fr.stream_id = 1
        fr.error_code = Arf::Wire::ERROR_CODE_CANCEL
      end)

      expect(subject.state).to be_closed
    end

    it "ignores incoming DataFrames" do
      expect(driver).to receive(:dispatch).with(kind_of(Arf::Wire::ResetStreamFrame))
      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = 1
        fr.end_data!
        fr.payload = [0x00, 0x01, 0x02].pack("C*")
      end)

      expect { subject.read }.to raise_error(Arf::Wire::ClosedStreamError)
    end
  end

  context "half-closed local" do
    it "transitions to closed receiving DATA with END_STREAM" do
      expect(driver).to receive(:dispatch).with(kind_of(Arf::Wire::DataFrame))
      subject.close_local
      expect(subject.state).to be_local_closed

      subject.handle_data(Arf::Wire::DataFrame.new do |fr|
        fr.stream_id = 1
        fr.end_stream!
      end)

      expect(subject.state).to be_closed
    end
  end
end
