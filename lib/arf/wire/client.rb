# frozen_string_literal: true

module Arf
  module Wire
    class Client < BaseConnection
      def post_init
        dispatch_frame(HelloFrame) do |fr|
          compression = Arf.config.client_compression
          case compression
          when :gzip
            fr.compression_gzip!
          else
            Arf.config.client_compression = :none
          end

          @compression = Arf.config.client_compression
        end
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

      def handle_go_away(fr)
        return protocol_error! unless @configured

        # server intends to disconnect
        cancel_streams(fr.error_code)
        close_connection_after_writing
      end

      def handle_reset_stream(fr)
        return protocol_error! unless @configured

        str = fetch_stream(fr.stream_id)
        return protocol_error! unless str

        str.handle_reset_stream(fr)
      end

      def handle_hello(fr)
        return protocol_error! if !fr.ack? || @configured

        @configured = true
        @hello_ready_lock.synchronize do
          @hello_ready_signal.broadcast
        end
      end

      def handle_data(fr)
        return protocol_error! unless @configured

        str = fetch_stream(fr.stream_id)
        return reset_stream(fr.stream_id, ERROR_CODE_PROTOCOL_ERROR) unless str

        str.handle_data(fr)
      end

      def new_stream
        wait_hello
        id = nil
        @streams_monitor.synchronize do
          @last_stream_id += 1
          id = @last_stream_id
          @streams[id] = Stream.new(id, self)
          dispatch_frame(MakeStreamFrame) do |fr|
            fr.stream_id = id
          end
        end
        @streams[id]
      end

      def terminate(reason)
        dispatch_frame(GoAwayFrame) do |g|
          g.error_code = reason
          g.last_stream_id = @last_stream_id
        end
        close_connection_after_writing
      end

      def close
        wait_hello
        @streams_monitor.synchronize do
          close_connection
        end
      end
    end
  end
end
