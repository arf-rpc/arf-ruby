# frozen_string_literal: true

module Arf
  class Server
    def self.pseudo_uuid
      hostname = Socket.gethostname
      lambda do
        "#{hostname}-#{SecureRandom.hex(8)}"
      end
    end

    def default_options
      @default_options ||= {
        max_concurrent_streams: 0,
        logger: Arf.configuration.logger,
        id_generator: Server.pseudo_uuid
      }.merge
    end

    def initialize(**opts)
      opts = default_options.merge(opts)
      opts[:id_generator] ||= Server.pseudo_uuid
      @logger = opts[:logger]
      @id_generator = opts[:id_generator]
      @max_concurrent_streams = opts[:max_concurrent_streams]
      @server = Arf::Wire::Server.new(self)
      @interceptors = []
    end

    def register_interceptor(callable, &block)
      callable ||= block
      @interceptors << callable
    end

    def run = @server.run
    def shutdown = @server.shutdown

    def handle_stream(stream)
      req_id = @id_generator.call
      stream.external_id = req_id
      log = @logger.with_fields(request_id: req_id)
      log.debug("Servicing stream")
      ctx = Context.new(req_id, log, stream)
      log.debug("Reading request...", thread: Thread.current.name)
      msg = RPC::BaseMessage.initialize_from(stream.read_blocking)
      unless msg.is_a? RPC::Request
        log.info("Rejecting stream as it does not start with a Request frame")
        stream.write_data(RPC::BaseMessage.encode(RPC::Response.new(
                                                    status: :failed_precondition,
                                                    metadata: {
                                                      "arf-request-id" => req_id,
                                                      "arf-status-description" => "Missing Request frame"
                                                    }
                                                  )))
        stream.close_local
        return
      end

      log.debug("Request read OK")
      ctx.request = msg
      # chain interceptors
      call_next(0, ctx)
      handle_request(ctx)
    end

    def handle_request(ctx)
      base_svc = Arf::RPC::ServiceBase.by_id(ctx.request.service)
      svc = base_svc&.subclasses&.first

      if svc.nil?
        ctx.log.info("Rejecting request as there's no service registered with the requested name",
                     service: ctx.request.service, method: ctx.request.method)
        failure(ctx, :unimplemented)
        return false
      end

      unless svc.respond_to_rpc?(ctx.request.method)
        ctx.log.info("Rejecting request as service does not respond to the requested method",
                     service: ctx.request.service, method: ctx.request.method)
        failure(ctx, :unimplemented)
        return false
      end

      ctx.log.debug("Handler got request")

      svc_inst = svc.new

      begin
        result = svc_inst.arf_execute_request(ctx)
      rescue Status::BadStatus => e
        failure(ctx, e.code, e.message)
        return false
      rescue Exception => e
        ctx.log.error("Failed invoking method #{ctx.request.method}", e)
        failure(ctx, :internal_error)
        return false
      end

      ctx.end_send if ctx.has_send_stream
      svc_inst.respond(result) unless ctx.has_sent_response
      true
    end

    def failure(ctx, status, message = nil)
      resp = RPC::Response.new(
        status: Status::FROM_SYMBOL[status],
        metadata: {
          "arf-status-description" => message || Status::STATUS_TEXT[status]
        }
      )
      ctx.stream.write_data(RPC::BaseMessage.encode(resp), end_stream: true)
      ctx.has_sent_response = true
    end

    def cancel_stream(stream); end

    def call_next(index, ctx)
      return unless index < @interceptors.size

      @interceptors[index].call(ctx) { call_next(index + 1, ctx) }
    end
  end
end
