# frozen_string_literal: true

module RPCHelpers
  class SampleService < Arf::RPC::ServiceBase
    arf_service_id "org.example.arf.spec/sample_service"

    # no_input__no_output__no_input_stream__no_output_stream() -> void
    rpc :no_input__no_output__no_input_stream__no_output_stream

    # no_input__no_output__no_input_stream__output_stream() -> OutputStream[string]
    rpc :no_input__no_output__no_input_stream__output_stream,
        outputs: OutputStream[:string]

    # no_input__no_output__input_stream__no_output_stream() -> InputStream[string]
    rpc :no_input__no_output__input_stream__no_output_stream,
        inputs: { _stream: InputStream[:string] }

    # no_input__no_output__input_stream__output_stream() -> InOutStream[string, string]
    rpc :no_input__no_output__input_stream__output_stream,
        inputs: { _stream: InputStream[:string] },
        outputs: OutputStream[:string]

    # no_input__output__no_input_stream__no_output_stream() -> string
    rpc :no_input__output__no_input_stream__no_output_stream,
        outputs: :string

    # no_input__output__no_input_stream__output_stream() -> [string, OutputStream[string]]
    rpc :no_input__output__no_input_stream__output_stream,
        outputs: [:string, OutputStream[:string]]

    # no_input__output__input_stream__no_output_stream() -> [string, InputStream[string]]
    rpc :no_input__output__input_stream__no_output_stream,
        inputs: { _stream: InputStream[:string] },
        outputs: :string

    # no_input__output__input_stream__output_stream() -> [string, InOutStream[string, string]]
    rpc :no_input__output__input_stream__output_stream,
        inputs: { _stream: InputStream[:string] },
        outputs: [:string, OutputStream[:string]]

    # input__no_output__no_input_stream__no_output_stream(string) -> void
    rpc :input__no_output__no_input_stream__no_output_stream,
        inputs: { i: :string }

    # input__no_output__no_input_stream__output_stream(string) -> [string, OutputStream[string]]
    rpc :input__no_output__no_input_stream__output_stream,
        inputs: { i: :string },
        outputs: OutputStream[:string]

    # input__no_output__input_stream__no_output_stream(string) -> InputStream[string]
    rpc :input__no_output__input_stream__no_output_stream,
        inputs: { i: :string, _stream: InputStream[:string] }

    # input__no_output__input_stream__output_stream(string) -> InOutStream[string, string]
    rpc :input__no_output__input_stream__output_stream,
        inputs: { i: :string, _stream: InputStream[:string] },
        outputs: OutputStream[:string]

    # input__output__no_input_stream__no_output_stream(string) -> string
    rpc :input__output__no_input_stream__no_output_stream,
        inputs: { i: :string }, outputs: :string

    # input__output__no_input_stream__output_stream(string) -> [string, OutputStream[string]]
    rpc :input__output__no_input_stream__output_stream,
        inputs: { i: :string },
        outputs: [:string, OutputStream[:string]]

    # input__output__input_stream__no_output_stream(string) -> [string, InputStream[string]]
    rpc :input__output__input_stream__no_output_stream,
        inputs: { i: :string, _stream: InputStream[:string] },
        outputs: :string

    # input__output__input_stream__output_stream(string) -> [string, InOutStream[stirng, string]]
    rpc :input__output__input_stream__output_stream,
        inputs: { i: :string, _stream: InputStream[:string] },
        outputs: [:string, OutputStream[:string]]
  end

  class SampleClient < Arf::RPC::ClientBase
    arf_service_id "org.example.arf.spec/sample_service"

    rpc :no_input__no_output__no_input_stream__no_output_stream

    rpc :no_input__no_output__no_input_stream__output_stream,
        outputs: OutputStream[:string]

    rpc :no_input__no_output__input_stream__no_output_stream,
        inputs: { _stream: InputStream[:string] }

    rpc :no_input__no_output__input_stream__output_stream,
        inputs: { _stream: InputStream[:string] },
        outputs: OutputStream[:string]

    rpc :no_input__output__no_input_stream__no_output_stream,
        outputs: :string

    rpc :no_input__output__no_input_stream__output_stream,
        outputs: [:string, OutputStream[:string]]

    rpc :no_input__output__input_stream__no_output_stream,
        inputs: { _stream: InputStream[:string] },
        outputs: :string

    rpc :no_input__output__input_stream__output_stream,
        inputs: { _stream: InputStream[:string] },
        outputs: [:string, OutputStream[:string]]

    rpc :input__no_output__no_input_stream__no_output_stream,
        inputs: { i: :string }

    rpc :input__no_output__no_input_stream__output_stream,
        inputs: { i: :string },
        outputs: OutputStream[:string]

    rpc :input__no_output__input_stream__no_output_stream,
        inputs: { i: :string, _stream: InputStream[:string] }

    rpc :input__no_output__input_stream__output_stream,
        inputs: { i: :string, _stream: InputStream[:string] },
        outputs: OutputStream[:string]

    rpc :input__output__no_input_stream__no_output_stream,
        inputs: { i: :string }, outputs: :string

    rpc :input__output__no_input_stream__output_stream,
        inputs: { i: :string },
        outputs: [:string, OutputStream[:string]]

    rpc :input__output__input_stream__no_output_stream,
        inputs: { i: :string, _stream: InputStream[:string] },
        outputs: :string

    rpc :input__output__input_stream__output_stream,
        inputs: { i: :string, _stream: InputStream[:string] },
        outputs: [:string, OutputStream[:string]]
  end

  class SampleServiceState
    attr_accessor :received_items
  end

  def self.service_state
    @service_state ||= SampleServiceState.new
  end

  def self.reset_service_state!
    @service_state = nil
  end

  class SampleServiceImpl < SampleService
    def no_input__no_output__no_input_stream__no_output_stream
      # Noop!
    end

    def no_input__output__no_input_stream__no_output_stream
      "Hello!"
    end

    def no_input__no_output__no_input_stream__output_stream
      yield "Hello!"
      yield "World!"
    end

    def no_input__no_output__input_stream__no_output_stream
      state = RPCHelpers.service_state
      state.received_items = []
      state.received_items << recv
      state.received_items << recv
    end

    def state = RPCHelpers.service_state

    def no_input__no_output__input_stream__output_stream
      state.received_items = []
      state.received_items << recv
      state.received_items << recv
      yield "S1"
      yield "S2"
    end

    def no_input__output__no_input_stream__output_stream
      respond "Hello!"
      yield "S1"
      yield "S2"
    end

    def no_input__output__input_stream__no_output_stream
      state.received_items = []
      state.received_items << recv
      state.received_items << recv
      "Hello!"
    end

    def no_input__output__input_stream__output_stream
      state.received_items = []
      state.received_items << recv
      state.received_items << recv
      respond "Hello!"
      yield "S1"
      yield "S2"
    end

    def input__no_output__no_input_stream__no_output_stream(val)
      state.received_items = []
      state.received_items << val
    end

    def input__no_output__no_input_stream__output_stream(val)
      yield val
    end

    def input__no_output__input_stream__no_output_stream(val)
      state.received_items = []
      state.received_items << val
      state.received_items << recv
      state.received_items << recv
    end

    def input__no_output__input_stream__output_stream(val)
      state.received_items = []
      state.received_items << val
      state.received_items << recv
      state.received_items << recv
      yield "S1"
      yield "S2"
    end

    def input__output__no_input_stream__no_output_stream(val)
      val
    end

    def input__output__no_input_stream__output_stream(val)
      respond val
      yield "S1"
      yield "S2"
    end

    def input__output__input_stream__no_output_stream(val)
      state.received_items = []
      state.received_items << recv
      state.received_items << recv
      respond val
    end

    def input__output__input_stream__output_stream(val)
      state.received_items = []
      state.received_items << recv
      state.received_items << recv
      respond val
      yield "S1"
      yield "S2"
    end
  end
end
