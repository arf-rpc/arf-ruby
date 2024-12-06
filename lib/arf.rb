# frozen_string_literal: true

require "stringio"
require "securerandom"
require "openssl"
require "monitor"

Thread.abort_on_exception = true

require "zlib"
require "brotli"
require "logrb"
require "nio"
require "concurrent"

require_relative "arf/version"
require_relative "arf/configuration"
require_relative "arf/reactor"
require_relative "arf/errors"
require_relative "arf/io/buffer"
require_relative "arf/io/limit_reader"
require_relative "arf/io/compression"
require_relative "arf/observer"
require_relative "arf/types"
require_relative "arf/proto"
require_relative "arf/wire"
require_relative "arf/status"
require_relative "arf/rpc"
require_relative "arf/context"
require_relative "arf/server"

module Arf
  def self.configure
    inst = Configuration.instance
    yield inst if block_given?
    nil
  end

  def self.configuration = Configuration.instance
  def self.config = configuration
  def self.logger = configuration.logger

  def self.connect(host, port)
    Reactor.connect(host, port, Wire::Client)
  end
end
