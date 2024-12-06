# frozen_string_literal: true

module Arf
  module Wire
    class Frame
      MAGIC = "arf"
      MAGIC_SIZE = 3
      STREAM_ID_SIZE = 4
      FRAME_KIND_SIZE = 1
      FLAGS_SIZE = 1
      LENGTH_SIZE = 2
      FRAME_SIZE = MAGIC_SIZE + STREAM_ID_SIZE + FRAME_KIND_SIZE + FLAGS_SIZE + LENGTH_SIZE

      attr_accessor :stream_id, :frame_kind, :flags, :length
      attr_reader :payload

      def empty? = length ? length.zero? : true

      def self.read_exactly(io, into, n)
        into.truncate(0)
        into.write(io.read(n - into.length)) until into.length == n
        into.rewind
        into
      end

      def self.from_io(io)
        buf = StringIO.new
        read_exactly(io, buf, FRAME_SIZE)
        raise MagicNumberMismatchError if buf.read(3) != Frame::MAGIC

        stream_id = Wire.decode_uint32(buf)
        raw_kind = buf.readbyte
        frame_kind = Wire::FRAME_TO_SYMBOL[raw_kind]
        raise UnknownFrameKindError, raw_kind unless frame_kind

        flags = buf.readbyte
        length = Wire.decode_uint16(buf)
        payload = nil
        if length.positive?
          payload = StringIO.new
          read_exactly(io, payload, length)
        end

        new.tap do |f|
          f.stream_id = stream_id
          f.frame_kind = frame_kind
          f.flags = flags
          f.payload = payload
          f.length = length
        end
      end

      def bytes(compressor)
        @payload = IO::COMPRESSOR[compressor].compress(@payload)
        @length = @payload&.length || 0

        IO::Buffer.new
          .write_raw(MAGIC)
          .write_raw(Wire.encode_uint32(@stream_id || 0))
          .write_raw([SYMBOL_TO_FRAME[@frame_kind]].pack("C*"))
          .write_raw(@flags || 0)
          .write_raw(Wire.encode_uint16(@length))
          .write_raw(@payload&.string || "")
          .string
      end

      def validate_kind(expected, associated)
        raise FrameMismatchError.new(expected, @frame_kind) if @frame_kind != expected

        if associated && (@stream_id.nil? || @stream_id.zero?)
          raise UnexpectedUnassociatedFrameError, @frame_kind
        elsif !associated && (!@stream_id.nil? && @stream_id != 0)
          raise UnexpectedAssociatedFrameError, @frame_kind
        end
      end

      def validate_size(size)
        return unless @length != size

        raise InvalidFrameLengthError, "invalid length for frame #{@frame_kind} " \
                                       "#{size} bytes are required, received #{@length}"
      end

      def decompress(compressor)
        @payload = IO::COMPRESSOR[compressor].decompress(@payload)
        @length = @payload&.length || 0
      end

      def payload=(value)
        if value.nil?
          @payload = nil
          return
        end

        @payload = if value.is_a? StringIO
                     value
                   else
                     StringIO.new(value)
                   end
      end

      def specialize(compressor)
        cls = BaseFrame.frame_by_kind(@frame_kind)
        raise UnknownFrameKindError, @frame_kind if cls.nil?

        decompress(compressor)
        cls.new(self)
      end
    end
  end
end
