# frozen_string_literal: true

require_relative "server/peer"

module Arf
  module Wire
    class Server
      def initialize(handler)
        @peers = {}
        @peer_id = 0
        @peers_monitor = Monitor.new
        @handler = handler
        @logger = Arf.logger.with_fields(subsystem: "Server")
      end

      def register_peer(peer)
        @logger.debug("Registered peer", peer: peer.class.name)
        @peers_monitor.synchronize do
          id = @peer_id
          @peer_id += 1
          @peers[id] = peer
          id
        end
      end

      def unregister_peer(id)
        @peers_monitor.synchronize do
          @peers.delete(id)
        end
      end

      def peer_by_id(id)
        @peers_monitor.synchronize do
          @peers[id]
        end
      end

      def handle_stream(str)
        @logger.debug("Handle Stream received")
        @handler&.handle_stream(str)
      end

      def cancel_stream(str) = @handler&.cancel_stream(str)

      def shutdown
        return unless @tcp_server

        @tcp_server.close
        Arf::Reactor.detach(@tcp_server)
        @peers_monitor.synchronize do
          @peers.each_value { _1.go_away! ERROR_CODE_NO_ERROR, terminate: true }
        end
      end

      def run
        config = Arf.config
        @tcp_server = TCPServer.new(config.bind_address, config.bind_port)
        @tcp_server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
        Arf::Reactor.attach_server(@tcp_server, Peer, self)
      end
    end
  end
end
