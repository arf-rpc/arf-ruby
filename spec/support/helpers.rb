# frozen_string_literal: true

module Helpers
  def random_stream_id = SecureRandom.bytes(4).unpack1("L>")

  def get_server_peers(srv)
    srv.instance_variable_get(:@peers).values
  end

  def wait_for_stream(conn)
    start = Time.now.to_i
    until conn.instance_variable_get(:@streams).length.positive?
      sleep 0.1
      raise "Waited for stream for over 5 seconds. It won't arrive." if Time.now.to_i - start > 5
    end
    conn.instance_variable_get(:@streams).values.last
  end

  def wait_for_reset(stream)
    start = Time.now.to_i
    until stream.state.closed?
      sleep 0.1
      raise "Waited for stream for over 5 seconds. It won't close." if Time.now.to_i - start > 5
    end
  end

  def wait_for_read(stream)
    start = Time.now.to_i
    while stream.instance_variable_get(:@to_read).empty?
      sleep 0.1
      raise "Waited for data for over 5 seconds. It won't arrive." if Time.now.to_i - start > 5
    end
  end

  def wait_for_received_items(len: nil)
    len = 1 if len.nil?

    start = Time.now.to_i
    loop do
      return if RPCHelpers.service_state.received_items&.length&.>= len

      sleep 0.1
      raise "Waited for received_items for over 5 seconds. It won't arrive." if Time.now.to_i - start > 5
    end
  end

  def dispatch_frame(cls, &)
    fr = cls.new(&)
    data = fr.to_frame.bytes(defined?(compression) ? compression : :none)
    subject.recv(data)
  end

  class DummyHandler
    def initialize(queue)
      @queue = queue
    end

    def handle_data(data)
      @queue << data
    end
  end

  def attach_dummy_handler(stream)
    Thread::Queue.new.tap do |q|
      stream.attach_handler(DummyHandler.new(q))
    end
  end
end
