# frozen_string_literal: true

module Arf
  module RPC
    class ClientBase
      include Arf::Types::Mixin

      def self.arf_service_id(id)
        @arf_service_id = id
      end

      def self.rpc(name, inputs: nil, outputs: nil)
        @rpc_metadata ||= {}
        inputs ||= {}
        outputs = [outputs].compact unless outputs.is_a? Array

        @rpc_metadata[name] = {
          name:, inputs: inputs.dup, outputs: outputs.dup
        }

        inputs = inputs.to_a
          .map do |type|
            if type.last.is_a? InputStream
              outputs << type.last
              next nil
            end
            type
          end
          .compact.to_h

        if outputs.length > 1 && outputs[-2].is_a?(Streamer) && outputs[-1].is_a?(Streamer)
          input = outputs.find { _1.is_a? InputStream }
          output = outputs.find { _1.is_a? OutputStream }

          outputs = outputs[...-2]
          outputs << InOutStream[input.type, output.type]
        end

        @rpc_metadata[name][:native_inputs] = inputs
        @rpc_metadata[name][:native_outputs] = outputs

        internal_name = "_#{name}"
        service_name = @arf_service_id

        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          # def name(param, param, param, **metadata, &block)
          #   internal_name(params, param, param, **metadata, &block)
          # end
          def #{name}(#{inputs.keys.join(", ")}#{inputs.length.positive? ? ", " : ""}**metadata, &block)
            #{internal_name}(#{inputs.keys.join(", ")}#{inputs.length.positive? ? ", " : ""}**metadata, &block)
          end
        RUBY

        define_method(internal_name) do |*args, **metadata, &block|
          _invoke_method(service_name, name, inputs.values, outputs, args, metadata, &block)
        end
      end

      def initialize(client)
        @client = client
      end

      def _invoke_method(service_id, method_name, inputs, outputs, args, meta)
        mapped_args = args.map.with_index do |v, idx|
          raw_type = case (t = inputs[idx])
                     when Symbol then t
                     when String then self.class.find_type(t)
                     else
                       raise ArgumentError, "Unknown type definition #{v.inspect}"
                     end

          Arf::Types.coerce_value(v, raw_type)
        end

        # Obtain a stream from @client
        str = @client.new_stream

        # Push the request
        streaming = outputs.any? { _1.is_a?(InputStream) || _1.is_a?(InOutStream) }
        req = Request.new(
          streaming:,
          metadata: meta,
          service: service_id,
          method: method_name,
          params: mapped_args
        )

        input_type = nil
        output_type = nil

        streamer = outputs.last
        case streamer
        when InputStream
          input_type = streamer.resolved_type(self.class)
        when OutputStream
          output_type = streamer.resolved_type(self.class)
        when InOutStream
          input_type = streamer.resolved_input(self.class)
          output_type = streamer.resolved_output(self.class)
        end

        resp = Responder.new(str, input_type, output_type)

        str.write_data(BaseMessage.encode(req), end_stream: !streaming)

        resp
      end
    end
  end
end
