# frozen_string_literal: true

require_relative "stream/state"

module Arf
  module Wire
    class Stream
      attr_reader :id, :state
      attr_accessor :external_id

      def initialize(id, driver)
        @id = id
        @driver = driver
        @state = State.new
        @tmp_data = StringIO.new
        @to_read_monitor = Monitor.new
        @to_read = Queue.new
        @handler = nil
        @log = Arf.logger.with_fields(component: "Stream", driver: @driver.class.name)
      end

      def attach_handler(handler)
        @log.debug("Attached handler", handler:)
        @handler = handler
        @to_read_monitor.synchronize do
          @handler.handle_data(@to_read.shift) until @to_read.empty?
        end
      end

      def handle_reset_stream(fr)
        # return if @state.closed? # Ignore resets when stream is closed
        @state.may_reset_stream?
        @state.close
        @state.error = StreamResetError.new(fr.error_code)
      rescue ClosedStreamError
        reset!(Wire::ERROR_CODE_STREAM_CLOSED)
      end

      def handle_data(fr)
        @state.may_receive_data?
        data = case fr.payload
               when StringIO then fr.payload.string
               when String then fr.payload
               else fr.payload.to_s
               end

        @tmp_data.write(data)

        if fr.end_data? && @tmp_data.length.positive?
          @tmp_data.rewind
          @to_read_monitor.synchronize do
            if @handler && @to_read.empty?
              @handler.handle_data(@tmp_data)
            else
              @to_read << @tmp_data
            end
            @tmp_data = StringIO.new
          end
        end
        @state.close_remote if fr.end_stream?
      rescue ClosedStreamError
        reset!(Wire::ERROR_CODE_STREAM_CLOSED)
      end

      def reset!(code)
        write(ResetStreamFrame) do |fr|
          fr.stream_id = @id
          fr.error_code = code
        end
      end

      def reset(code)
        @state.may_send_reset_stream?
        @state.close
        reset!(code)
      end

      def close_local
        @state.may_send_data?
        @state.close_local
        write(DataFrame) do |fr|
          fr.end_data!
          fr.end_stream!
        end
      end

      def read
        raise @state.error if @state.error

        begin
          val = @to_read.shift(true)
          return val if val
        rescue ThreadError
          nil
        end

        @state.may_receive_data?
        nil
      end

      def read_blocking
        raise @state.error if @state.error

        val = @to_read.shift
        return val if val

        nil
      end

      def write(type, &)
        @log.debug("Dispatching", type:)
        inst = type.new(&)
        inst.stream_id = @id if inst.respond_to?(:stream_id=)
        @driver.dispatch(inst)
      end

      def write_data(value, end_stream: false)
        @state.may_send_data?

        @log.dump("Writing", value, source: caller[0])
        Wire.data_frames_from_buffer(@id, value, end_stream:).each do |fr|
          @driver.dispatch(fr)
        end
        @state.close_local if end_stream
      end
    end
  end
end
