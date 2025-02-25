# frozen_string_literal: true

module Arf
  module Wire
    class BaseConnection
      def initialize
        @_write_lock = Monitor.new
        @_write_buffer = Queue.new
        @_write_head = nil
        @compression = :none
        @last_stream_id = 0
        @reader = FrameReader.new
        @configured = false
        @pong_signal = WaitSignal.new

        @streams = {}
        @streams_monitor = Monitor.new

        @hello_ready_lock = Mutex.new
        @hello_ready_signal = Thread::ConditionVariable.new
        @registered = false
      end

      def registered? = @registered

      def registered!
        @registered = true
        @_write_lock.synchronize do
          Arf::Reactor.client_writes_pending(self) unless @_write_buffer.empty?
        end
      end

      def wait_hello
        return if @configured

        loop do
          @hello_ready_lock.synchronize do
            @hello_ready_signal.wait(@hello_ready_lock)
            return if @configured
          end
        end
      end

      def recv(data)
        data.each_byte do |b|
          v = @reader.feed(b)
          next unless v

          handle_frame(v)
        end
      end

      def handle_frame(raw_frame)
        frame = raw_frame.specialize(@compression)
        case frame
        when HelloFrame
          handle_hello(frame)
        when PingFrame
          handle_ping(frame)
        when GoAwayFrame
          handle_go_away(frame)
        when MakeStreamFrame
          handle_make_stream(frame)
        when ResetStreamFrame
          handle_reset_stream(frame)
        when DataFrame
          handle_data(frame)
        else
          protocol_error!
        end
      rescue UnknownFrameKindError, InvalidFrameLengthError
        protocol_error!
      end

      def cancel_streams(code)
        @streams_monitor.synchronize do
          @streams.each_value do |v|
            v.reset(code)
          rescue ClosedStreamError, StreamResetError
            next
          end
        end
      end

      def ping
        wait_hello
        @streams_monitor.synchronize do
          dispatch_frame(PingFrame) do |p|
            p.payload = SecureRandom.bytes(8)
          end
        end
      end

      def wait_pong = @pong_signal.wait

      def fetch_stream(id) = @streams_monitor.synchronize { @streams[id] }

      def arf_close_after_writing?
        @arf_close_after_writing || false
      end

      def close_connection = Reactor.detach_client(self)

      def close
        close_connection
      end

      def close_connection_after_writing
        @arf_close_after_writing = true
      end

      def send_data(data)
        @_write_lock.synchronize do
          @_write_buffer << data
        end
        Reactor.client_writes_pending(self) if registered?
        data.bytesize
      end

      def handle_ping(fr)
        return protocol_error! unless @configured

        if fr.ack?
          @pong_signal.broadcast
          return
        end

        dispatch_frame(PingFrame) do |p|
          p.ack!
          p.payload = fr.payload
        end
      end

      def dispatch_frame(type, terminate: false, &)
        dispatch(type.new(&))
        close_connection_after_writing if terminate
      end

      def dispatch(frame)
        send_data(frame.to_frame.bytes(@compression))
      end

      def protocol_error! = go_away!(ERROR_CODE_PROTOCOL_ERROR, terminate: true)

      def go_away!(code, extra_data: nil, terminate: false)
        dispatch_frame(GoAwayFrame, terminate:) do |g|
          g.last_stream_id = @last_stream_id
          g.error_code = code
          g.additional_data = extra_data if extra_data
        end
      end

      def flush_write_buffer(io)
        @_write_lock.synchronize do
          loop do
            if @_write_head.nil?
              return true if @_write_buffer.empty?

              @_write_head = @_write_buffer.pop
            end

            written = io.write_nonblock(@_write_head, exception: false)
            case written
            when :wait_writable
              return false
            when @_write_head.bytesize
              @_write_head = nil
            else
              @_write_head = @_write_head.byteslice(written, @_write_head.bytesize)
              return false
            end
          end
        end
      end
    end
  end
end
