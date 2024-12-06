# frozen_string_literal: true

module Arf
  module RPC
    class ServiceBase
      include Arf::Types::Mixin

      class YieldWithoutRespondError < Arf::Error
        def initialize
          super("This RPC method has response fields that must be sent before " \
                "starting a stream. Please invoke #respond with the response " \
                "parameters before yielding a value to the stream.")
        end
      end

      class YieldWithoutStreamError < Arf::Error
        def initialize
          super("This RPC method does not have an output stream and cannot " \
                "yield values.")
        end
      end

      class YieldOnClosedStream < Arf::Error
        def initialize
          super("Cannot call yield after closing the output stream.")
        end
      end

      def self.register(id, cls)
        @services ||= {}
        @services[id] = cls
      end

      def self.by_id(id)
        @services ||= {}
        @services[id]
      end

      def self.arf_service_id(id)
        @arf_service_id = id
        ::Arf::RPC::ServiceBase.register(id, self)
      end

      def self.respond_to_rpc?(name)
        return true if @service_methods&.key?(name.to_sym)

        if superclass != Arf::RPC::ServiceBase && superclass.respond_to?(:respond_to_rpc?)
          return superclass.respond_to_rpc?(name)
        end

        false
      end

      def self.rpc_method_meta(name)
        name = name.to_sym unless name.is_a? Symbol
        return @service_methods[name] if @service_methods&.key?(name)

        if superclass != Arf::RPC::ServiceBase && superclass.respond_to?(:rpc_method_meta)
          return superclass.rpc_method_meta(name)
        end

        nil
      end

      def self.rpc(name, inputs: nil, outputs: nil)
        inputs ||= {}
        outputs = [outputs].compact unless outputs.is_a? Array

        @service_methods ||= {}
        @service_methods[name] = MethodMeta.new(inputs, outputs)
        define_method(name) { unimplemented! }
      end

      attr_reader :log, :request

      def arf_execute_request(ctx)
        @context = ctx
        @request = ctx.request
        @metadata = @request.metadata
        @service = @request.service
        @method = @request.method
        @log = ctx.log
        @method_meta = self.class.rpc_method_meta(@method)
        needs_response = @method_meta.output?
        @context.prepare
        if (str = @method_meta.output_stream)
          @context.has_send_stream = true
          @context.send_stream_type = str
        end

        @context.response.metadata.attach_observer(self)

        output_type = @method_meta.output_stream&.resolved_type(self.class)

        result = nil
        begin
          result = send(@method, *@request.params) do |val|
            raise YieldWithoutStreamError unless ctx.has_send_stream
            raise YieldWithoutRespondError if !ctx.has_sent_response && needs_response
            raise YieldOnClosedStream if ctx.send_stream_finished

            ctx.stream_send(Arf::Types.coerce_value(val, output_type))
            nil
          end
        rescue Exception => e
          @log.error("Failed executing ##{@method}", e)
          error!
        end
        @log.debug("Finished executing request", method: @method, result:)
        result
      end

      def observer_changed(_observer)
        # We just have a single observer, it will be response metadata.
        return unless ctx.send_stream_started && !ctx.send_stream_finished

        ctx.stream_send_metadata
      end

      def recv = @context.recv

      def set_meta(k, v) = @context.response.metadata.set(k, v)
      def add_meta(k, v) = @context.response.metadata.add(k, v)

      def respond(value, code: nil)
        code ||= :ok

        @context.response.params = @method_meta.coerce_result(value, self.class)
        @context.response.status = code
        @context.send_response
      end

      def unimplemented! = raise Status::BadStatus, :unimplemented
      def error! = raise Status::BadStatus, :internal_error
    end
  end
end
