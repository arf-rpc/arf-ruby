# frozen_string_literal: true

module Arf
  module RPC
    class Enum
      def self.option(**kwargs)
        @options ||= {}
        kwargs.each { |k, v| @options[k.to_sym] = v }
      end

      def self.option_by_name(name)
        @options ||= {}
        @options[name.to_sym]
      end

      def self.option_by_value(value)
        @options ||= {}
        @options.find { _2 == value }&.first
      end

      class << self
        attr_reader :options
      end

      def self.to_i(value)
        case value
        when Symbol, String
          option_by_name(value) or raise(ArgumentError, "Invalid value #{value.inspect} for #{self}")
        when Integer
          option_by_value(value) or raise(ArgumentError, "Invalid value #{value.inspect} for #{self}")
          value
        else
          raise ArgumentError, "Invalid value type #{value.class}. Expected Symbol, String or Integer."
        end
      end

      def self.to_sym(value)
        case value
        when Symbol, String
          value = value.to_sym
          option_by_name(value) or raise(ArgumentError, "Invalid value #{value.inspect} for #{self}")
          value
        when Integer
          option_by_value(value) or raise(ArgumentError, "Invalid value #{value.inspect} for #{self}")
        else
          raise ArgumentError, "Invalid value type #{value.class}. Expected Symbol, String or Integer."
        end
      end
    end
  end
end
