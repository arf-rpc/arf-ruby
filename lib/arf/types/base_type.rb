# frozen_string_literal: true

module Arf
  module Types
    class BaseType
      def bind(to) = tap { @bind = to }
      def coerce_value(*) = Arf::Types.coerce_value(*)

      def resolve_type(type)
        type.is_a?(String) ? @bind.find_type(type) : type
      end
    end
  end
end
