# frozen_string_literal: true

module Arf
  class Reactor
    BEAT_INTERVAL = 3

    def self.instance = (@instance ||= new)
    def self.connect(host, port, handler) = instance.connect(host, port, handler)
    def self.post(task = nil, &) = instance.post(task, &)
    def self.client_writes_pending(client) = instance.client_writes_pending(client)
    def self.detach_client(client) = instance.detach_client(client)
    def self.detach(io) = instance.detach(io)

    def self.attach_server(server, handler_class, *handler_args)
      instance.attach_server(server, handler_class, *handler_args)
    end

    def initialize
      @nio = @executor = @thread = nil
      @stopping = false
      @todo = Queue.new
      @spawn_lock = Monitor.new
      @map = {}
      @socket_source = {}
      @log = Arf.configuration.logger.with_fields(subsystem: "Reactor")
    end

    def timer(interval, &block)
      @log.debug("Attached timer", interval:, callable: block)
      Concurrent::TimerTask.new(execution_interval: interval, &block).tap(&:execute)
    end

    def connect(host, port, handler)
      @log.debug("Establishing connection", host:, port:, handler:)
      handler = handler.new
      @todo << lambda {
        addr_info = Socket.getaddrinfo(host, port, nil, Socket::SOCK_STREAM).first
        family = addr_info[4]
        io = Socket.new(family, Socket::SOCK_STREAM, 0)
        begin
          io.connect_nonblock Socket.sockaddr_in(port, host)
        rescue Errno::EINPROGRESS
          @log.debug("Connection in progress", id: handler.object_id)
          @map[io] = @nio.register(io, :w)
          @map[io].value = [host, port, handler]
          @socket_source[io] = :client
          next
        end
        @log.debug("Connection succeeded", id: handler.object_id)
        @map[io] = @nio.register(io, :r)
        @map[io].value = handler
        @socket_source[io] = :client
        @log.debug("Async post_init dispatch", id: handler.object_id)
        post { handler.registered! }
        post { handler.post_init } if handler.respond_to?(:post_init)
      }
      wakeup
      handler
    end

    def attach_server(server, handler_class, *handler_args)
      @log.debug("Attach server", server:, handler_class:)
      @todo << lambda {
        @map[server] = @nio.register(server, :r)
        @map[server].value = [handler_class, handler_args]
      }
      wakeup
    end

    def detach(io)
      @log.debug("Detach IO", io:)
      @todo << lambda {
        @nio.deregister(io)
        @map.delete(io)
        @socket_source.delete(io)
        io.close
      }
      wakeup
    end

    def detach_client(client)
      @log.debug("Detach client", client: client.class.name, id: client.object_id)
      @todo << lambda {
        io = io_for_client(client)
        next unless io

        @nio.deregister(io)
        @map.delete(io)
        @socket_source.delete(io)
        io.close
      }
      wakeup
    end

    def post(task = nil, &block)
      task ||= block
      spawn
      source = caller[0]
      @executor << lambda do
        task.call
      rescue Exception => e
        @log.error("Async post execution failed", e, source:)
      end
    end

    def io_for_client(client)
      @map.each do |k, v|
        return k if v.value == client
      end
      nil
    end

    def client_writes_pending(client)
      @log.debug("Writes pending", client: client.class.name, id: client.object_id)
      @todo << lambda {
        if (monitor = @map[io_for_client(client)])
          monitor.interests = :rw
        else
          @log.warn("No monitor for client", id: client.object_id)
        end
      }
      wakeup
      @log.debug("Writes pending registered")
    end

    private

    def spawn
      return if @thread&.alive?

      @spawn_lock.synchronize do
        return if @thread&.alive?

        @nio ||= NIO::Selector.new

        @executor ||= Concurrent::ThreadPoolExecutor.new(
          min_threads: 1,
          max_threads: 10,
          max_queue: 0
        )

        @thread = Thread.new { run }
        @thread.name = "Arf::Wire::Reactor loop"

        setup_ping_timer
        true
      end
    end

    def setup_ping_timer
      @setup_ping_timer ||= timer(BEAT_INTERVAL) do
        post do
          @map.each_value do |v|
            if v.is_a? Wire::BaseConnection
              @log.debug("Dispatch ping", client: v)
              v.ping
            end
          end
        end
      end
    end

    def handle_server_monitor(monitor)
      io = monitor.io
      handler, handler_args = monitor.value
      return unless monitor.readable?

      client = io.accept_nonblock
      inst = handler.new(*handler_args)
      # Basically #attach, but without the round-trip.
      @map[client] = @nio.register(client, :r)
      @map[client].value = inst
      @socket_source[client] = :server
      post { inst.registered! }
      post { inst.post_init } if inst.respond_to? :post_init
    end

    def handle_socket_monitor(monitor)
      io = monitor.io
      client = monitor.value

      if client.is_a? Array
        return unless monitor.writable?

        # This is a socket waiting for connection
        host, port, handler = client
        begin
          io.connect_nonblock Socket.sockaddr_in(port, host)
        rescue Errno::EISCONN
          monitor.value = handler
          monitor.interests = :r
          @log.debug("Async post_init dispatch", id: handler.object_id)
          post { handler.registered! }
          post { handler.post_init } if handler.respond_to?(:post_init)
        end
        return
      end

      begin
        if monitor.writable?
          if client.flush_write_buffer(io)
            monitor.interests = :r
            detach(io) if client.arf_close_after_writing?
          end
          return unless monitor.readable?
        end

        incoming = io.read_nonblock(4096, exception: false)
        case incoming
        when :wait_readable
          nil
        when nil
          post do
            client.close
          rescue Exception => e
            @log.error("Failed closing client", e, id: client.object_id)
            @nio.deregister(io)
            @map.delete(io)
            @socket_source.delete(io)
          end
        else
          post do
            client.recv(incoming)
          rescue Exception => e
            @log.error("Failed calling client.recv", e, id: client.object_id)
            begin
              client.close
            rescue Exception
              # noop
            ensure
              @nio.deregister(io)
              @map.delete(io)
              @socket_source.delete(io)
            end
          end
        end
      rescue Errno::EPIPE, Errno::ECONNRESET => e
        @log.error("Failed reading from client", e, id: client.object_id)
        @nio.deregister(io)
        @map.delete(io)
        @socket_source.delete(io)
      end
    end

    def wakeup
      spawn || @nio.wakeup
    end

    def run
      loop do
        if @stopping
          @nio.close
          break
        end

        @todo.pop(true).call until @todo.empty?

        next unless (monitors = @nio.select)

        monitors.each do |monitor|
          case monitor.io
          when TCPServer then handle_server_monitor(monitor)
          when TCPSocket, Socket then handle_socket_monitor(monitor)
          else raise "Unexpected monitor IO on reactor: #{monitor.io.inspect}"
          end
        end
      end
    end
  end
end
