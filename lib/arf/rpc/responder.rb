# frozen_string_literal: true

module Arf
  module RPC
    class Responder
      def initialize(str, input_stream_type, output_stream_type)
        @metadata = Metadata.new
        @stream = str

        @response = nil
        @response_error = nil
        @response_lock = Mutex.new
        @response_cond = Thread::ConditionVariable.new

        @input_stream_type = output_stream_type
        @has_input_stream = !output_stream_type.nil?
        @input_stream_started = false
        @input_stream_error = nil
        @input_stream_completed = false
        @input_stream_items = Queue.new
        @input_stream_closed_lock = Mutex.new
        @input_stream_closed = false

        @output_stream_type = input_stream_type
        @has_output_stream = !input_stream_type.nil?
        @output_stream_started_lock = Mutex.new
        @output_stream_started = false
        @output_stream_error = nil
        @output_stream_closed_lock = Mutex.new
        @output_stream_closed = false

        str.attach_handler(self)
      end

      def handle_data(value)
        msg = BaseMessage.initialize_from(value)
        case msg
        when Response
          @response_lock.synchronize do
            @response = msg
            @metadata.merge!(msg.metadata)
            if @response.status == :ok
              @params = msg.params
            else
              @response_error = Status::BadStatus.new(
                @response.status,
                @response.metadata.get("arf-status-description")
              )
            end
            @response_cond.broadcast
          end

        when StartStream
          @input_stream_started = true

        when EndStream
          @input_stream_completed = true
          @input_stream_items.close

        when StreamMetadata
          @metadata.replace!(msg.metadata)

        when StreamItem
          return if @input_stream_completed

          @input_stream_closed_lock.synchronize do
            return if @input_stream_closed
          end
          @input_stream_items << msg.value
        end
      end

      def push(value, **kwargs)
        raise ArgumentError, "#push receives either a value or kwargs, not both." if value && !kwargs.empty?

        raise RPC::NoStreamError, false unless @has_output_stream
        raise @output_stream_error if @output_stream_error

        # TODO: Warn? Error?
        return if @output_stream_closed

        @output_stream_closed_lock.synchronize do
          return if @output_stream_closed
        end

        @output_stream_started_lock.synchronize do
          next if @output_stream_started

          @stream.write_data(BaseMessage.encode(StartStream.new))
          @output_stream_started = true
        end

        @stream.write_data(BaseMessage.encode(StreamItem.new(value:)))
        value
      end

      alias << push

      def recv
        raise RPC::NoStreamError, true unless @has_input_stream
        raise @input_stream_error if @input_stream_error

        @input_stream_items.pop
      end

      def each
        loop do
          item = recv
          break if item.nil?

          yield item
        rescue StopIteration
          break
        end
        self
      end

      def close_send
        return if @output_stream_closed

        @output_stream_closed_lock.synchronize do
          @output_stream_closed = true
          @stream.write_data(BaseMessage.encode(EndStream.new))
        end
      end

      def close_recv
        return if @input_stream_closed

        @input_stream_closed_lock.synchronize do
          @input_stream_closed = true
          @input_stream_items.close
        end
      end

      def _wait_response(throw_error: true)
        raise @response_error if @response_error && throw_error

        return if @response

        catch :break_loop do
          loop do
            @response_lock.synchronize do
              @response_cond.wait(@response_lock)
              next if @response.nil?

              throw :break_loop
            end
          end
        end
      end

      def params
        _wait_response
        normalize_response_params
      end

      def normalize_response_params
        if @response.params.empty?
          nil
        elsif @response.params.length == 1
          @response.params.first
        else
          @response.params
        end
      end

      def metadata
        # It makes little sense to access metadata before a response is
        # received. Given that:
        _wait_response

        @metadata
      end

      def status
        _wait_response(throw_error: false)
        @response.status
      end

      def success?
        status == :ok
      end
    end
  end
end
