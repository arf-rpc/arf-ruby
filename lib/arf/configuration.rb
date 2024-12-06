# frozen_string_literal: true

module Arf
  class Configuration
    TLS_OPTS = {
      private_key_file: :tls_private_key_file,
      private_key: :tls_private_key,
      private_key_pass: :tls_private_key_pass,
      cert_chain_file: :tls_cert_chain_file,
      cert: :tls_cert,
      verify_peer: :tls_verify_peer,
      sni_hostname: :tls_sni_hostname,
      cipher_list: :tls_cipher_list,
      ssl_version: :tls_ssl_version,
      ecdh_curve: :tls_ecdh_curve,
      dhparam: :tls_dhparam,
      fail_if_no_peer_cert: :tls_fail_if_no_peer_cert
    }.freeze

    attr_accessor :bind_address, :bind_port,
                  :enable_tls, :tls_private_key_file, :tls_private_key,
                  :tls_private_key_pass, :tls_cert_chain_file, :tls_cert,
                  :tls_verify_peer, :tls_sni_hostname, :tls_cipher_list,
                  :tls_ssl_version, :tls_ecdh_curve, :tls_dhparam,
                  :tls_fail_if_no_peer_cert,
                  :client_compression
    attr_writer :logger

    # Determines the log verbosity level. Valid options are:
    # - :debug
    # - :info (default)
    # - :warn
    # - :fatal
    # - :error
    attr_reader :log_level

    def initialize
      @bind_address = "127.0.0.1"
      @bind_port = 2730
      @log_level = :info
    end

    def tls_configuration
      return @tls_configuration unless @tls_configuration.nil?

      @tls_configuration = TLS_OPTS
        .map { |k, v| [k, send(v)] }
        .compact
        .to_h
    end

    def enable_tls? = enable_tls

    def logger
      @logger ||= Logrb.new($stderr, level: @log_level)
    end

    def log_level=(level)
      @log_level = level
      logger.level = level
    end

    def self.instance
      @instance ||= new
    end
  end
end
