# frozen_string_literal: true

RSpec.describe Arf::Wire::Client do
  before(:all) do
    @server = Arf::Wire::Server.new(nil)
    @server.run
  end

  after(:all) do
    @server.shutdown
  end

  context("without compression") { it_behaves_like "a client", :none }
  context("with gzip") { it_behaves_like "a client", :gzip }
end
