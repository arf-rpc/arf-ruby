# frozen_string_literal: true

module Arf
  module Wire
    MAX_PAYLOAD = 65_535

    def self.encode_uint16(v) = [v].pack("S>")
    def self.encode_uint32(v) = [v].pack("L>")
    def self.decode_uint16(io) = io.read(2).unpack1("S>")
    def self.decode_uint32(io) = io.read(4).unpack1("L>")

    def self.data_frames_from_buffer(id, buf, end_stream: false)
      buf = case buf
            when StringIO then buf.string
            when String then buf
            else buf.to_s
            end

      len = buf.length
      if len <= MAX_PAYLOAD
        return [
          DataFrame.new do |fr|
            fr.stream_id = id
            fr.end_data!
            fr.end_stream! if end_stream
            fr.payload = buf
          end
        ]
      end

      frames = []
      written = 0
      loop do
        to_write = [len - written, MAX_PAYLOAD].min
        end_data = (len - written - to_write).zero?
        frames << DataFrame.new do |fr|
          fr.stream_id = id
          fr.end_data! if end_data
          fr.end_stream! if end_stream
          fr.payload = buf[written...written + to_write]
        end
        written += to_write
        break if end_data
      end

      frames
    end
  end
end
