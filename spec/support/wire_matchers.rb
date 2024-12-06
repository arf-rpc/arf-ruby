# frozen_string_literal: true

class SendFrameMatcher
  include RSpec::Matchers
  include RSpec::Matchers::DSL::DefaultImplementations
  include RSpec::Matchers::BuiltIn::BaseMatcher::DefaultFailureMessages

  def initialize(cls, receive_method, compression)
    @cls = cls
    @receive_method = receive_method
    @compression = compression
  end

  def matches?(executor, &block)
    expect(executor).to @receive_method.call(:send_data) do |data|
      fr = Arf::Wire::FrameReader.new
      v = fr.feed_all(data).specialize(@compression || :none)
      expect(v).to be_a @cls
      instance_exec(v, &block)
    end.once.ordered
  end
end

module Helpers
  def send_frame(cls)
    SendFrameMatcher.new(cls, method(:receive), defined?(compression) ? compression : :none)
  end
end
