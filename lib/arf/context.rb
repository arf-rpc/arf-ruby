# frozen_string_literal: true

module Arf
  class Context
    attr_accessor :request_id, :log, :stream, :request,
                  :has_recv_stream, :recv_stream_error, :recv_stream_started,
                  :has_send_stream, :send_stream_error, :send_stream_started, :send_stream_type, :send_stream_finished,
                  :has_sent_response, :response, :error

    def initialize(req_id, log, stream)
      @request_id = req_id
      @log = log
      @stream = stream

      @request = nil
      @error = nil

      @has_recv_stream = false
      @recv_stream_error = nil
      @recv_stream_started_lock = Monitor.new
      @recv_stream_started = false

      @has_send_stream = false
      @send_stream_error = nil
      @send_stream_started = false
      @send_stream_started_lock = Monitor.new
      @send_stream_finished = false
      @send_stream_type = nil

      @has_sent_response = false
      @response = Arf::RPC::Response.new
    end

    def prepare
      @has_recv_stream = @request.streaming
      @response.metadata.set("arf-request-id", @request_id)
    end

    def recv
      raise RPC::NoStreamError, true unless has_recv_stream
      raise @error if @error
      raise @recv_stream_error if @recv_stream_error

      loop do
        v = _read_stream_item
        return v if v
      end
    end

    def stream_send(val)
      raise RPC::NoStreamError, false unless @has_send_stream
      raise @error if @error
      raise @send_stream_error if @send_stream_error

      unless has_sent_response
        # Arf::RPC::Service makes sure this method can be called now. If it
        # allowed calling without a response being sent, it is acceptable to
        # push a response as-is, as the client does not expect parameters as
        # response other than the stream being sent.
        @log.debug("Pushing synthetic response for method without response values")
        @response.status = :ok
        @response.streaming = true
        @response.params = []
        send_response
      end

      begin
        unless @send_stream_started
          @send_stream_started_lock.synchronize do
            next if @send_stream_started

            @log.debug("Pushing StartStream frame")
            @stream.write_data(RPC::BaseMessage.encode(RPC::StartStream.new))
            @send_stream_started = true
          end
        end

        @log.debug("Pushing StreamItem frame")
        @stream.write_data(RPC::BaseMessage.encode(RPC::StreamItem.new(value: val)))
      rescue StandardError => e
        @send_stream_error = e
        raise
      end
    end

    def send_stream_metadata
      @stream.write_data(RPC::BaseMessage.encode(RPC::StreamMetadata.new(metadata: @response.metadata)))
    end

    def end_send
      return if @send_stream_finished
      raise RPC::NoStreamError, false unless @has_send_stream
      raise @error if @error
      raise @send_stream_error if @send_stream_error

      @send_stream_finished = true

      begin
        @stream.write_data(RPC::BaseMessage.encode(RPC::EndStream.new), end_stream: true)
      rescue StandardError => e
        @log.error("Failed running #end_send", e)
        @error = e
        raise
      end
    end

    def send_response(end_stream: false)
      @log.debug("Sending response", response: @response)

      @has_sent_response = true
      @send_stream_started = false

      @response.status ||= :ok
      @log.debug("Start stream write data")
      @stream.write_data(RPC::BaseMessage.encode(@response), end_stream:)
      @log.debug("Send response done")
    rescue Exception => e
      @log.error("Failed sending response", e)
      @error = e
      raise
    end

    private

    def _read_stream_item
      begin
        unless @recv_stream_started
          @recv_stream_started_lock.synchronize do
            next if @recv_stream_started

            msg = RPC::BaseMessage.initialize_from(@stream.read_blocking)
            if msg.is_a?(RPC::StartStream)
              @recv_stream_started = true
            else
              @error = RPC::StreamFailureError.new("Received unexpected message kind waiting for StartStream")
              raise @error
            end
          end
        end

        msg = RPC::BaseMessage.initialize_from(@stream.read_blocking)
      rescue StandardError => e
        @log.error("Failed starting recv_stream", e)
        @recv_stream_error = e
        raise
      end

      case msg
      when RPC::StreamItem
        msg.value

      when RPC::EndStream
        @recv_stream_error = RPC::StreamEndError.new
        raise @recv_stream_error

      when RPC::StreamError
        @recv_stream_error = msg
        raise @recv_stream_error

      when RPC::StreamMetadata
        @request.metadata.replace!(msg.metadata)
        nil

      else
        @error = RPC::StreamFailureError.new("Received unexpected message kind during stream")
        raise @error
      end
    end
  end
end
