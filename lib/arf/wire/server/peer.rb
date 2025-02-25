# frozen_string_literal: true

module Arf
  module Wire
    class Server
      class Peer < Wire::BaseConnection
        def initialize(server)
          super()
          @server = server
          @id = @server.register_peer(self)
          @log = Arf.logger.with_fields(subsystem: "Peer", id: @id)
        end

        def close
          super
          @server.unregister_peer(@id)
        end

        def handle_configuration(fr)
          return protocol_error! if @configured

          resp = ConfigurationFrame.new.tap(&:ack!)

          if fr.compression_gzip?
            @compression = :gzip
            resp.compression_gzip!
          end

          resp.max_concurrent_streams = 0 # TODO

          @configured = true
          @log.debug("Configuration OK")
          dispatch(resp)
        end

        def handle_go_away(fr)
          return protocol_error! unless @configured

          # client intends to disconnect
          cancel_streams(fr.error_code)
          close_connection_after_writing
        end

        def handle_make_stream(fr)
          return protocol_error! unless @configured
          return protocol_error! unless fetch_stream(fr.stream_id).nil?

          @streams_monitor.synchronize do
            @streams[fr.stream_id] = Stream.new(fr.stream_id, self)
          end
          @log.debug("Async dispatch handle_stream")
          Reactor.post { @server.handle_stream(@streams[fr.stream_id]) }
        end

        def handle_data(fr)
          return protocol_error! unless @configured

          str = fetch_stream(fr.stream_id)
          return reset_stream(fr.stream_id, ERROR_CODE_PROTOCOL_ERROR) unless str

          str.handle_data(fr)
        end

        def handle_reset_stream(fr)
          return protocol_error! unless @configured

          str = fetch_stream(fr.stream_id)
          return protocol_error! unless str

          str.handle_reset_stream(fr)
        end

        def reset_stream(id, code)
          dispatch_frame(ResetStreamFrame) do |r|
            r.stream_id = id
            r.error_code = code
          end
        end
      end
    end
  end
end
