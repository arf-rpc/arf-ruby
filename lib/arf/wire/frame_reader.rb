# frozen_string_literal: true

module Arf
  module Wire
    class FrameReader
      STATES = %i[
        magic
        stream_id
        kind
        flags
        length
        payload
      ].freeze

      def initialize
        @data = IO::Buffer.new
        @fr = Frame.new
        @state = :magic
        @c = 0
        @data.reset
      end

      def feed_all(data)
        c = 0
        data.each_byte do |b|
          v = feed b
          c += 1
          if v && c < data.length
            raise "Short read: Read #{c} bytes of #{data.length}"
          elsif v
            return v
          end
        end
        nil
      end

      def feed(b)
        case @state
        when :magic
          @data.write(b)
          return nil if @data.length < 3

          if @data.string != Frame::MAGIC
            @data.reset
            raise MagicNumberMismatchError
          end
          @data.reset
          @state = :stream_id

        when :stream_id
          @data.write(b)
          return nil if @data.length < 4

          @data.rewind
          @fr.stream_id = Wire.decode_uint32(@data)
          @data.reset
          @state = :kind

        when :kind
          raw_frame_kind = b
          frame_kind = Wire::FRAME_TO_SYMBOL[raw_frame_kind]
          raise UnknownFrameKindError, raw_frame_kind unless frame_kind

          @fr.frame_kind = frame_kind
          @state = :flags

        when :flags
          @fr.flags = b
          @state = :length

        when :length
          @data.write(b)
          return nil if @data.length < 2

          @data.rewind
          @fr.length = Wire.decode_uint16(@data)
          @data.reset
          @state = :payload
          if @fr.empty?
            @state = :magic
            frame = @fr
            @fr = Frame.new
            return frame
          end

        when :payload
          @data.write(b)
          return nil if @data.length < @fr.length

          @fr.payload = @data.extract
          @fr.payload.rewind
          @data = IO::Buffer.new
          @state = :magic
          @data.reset
          frame = @fr
          @fr = Frame.new
          return frame
        end

        nil
      end
    end
  end
end
