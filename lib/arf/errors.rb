# frozen_string_literal: true

module Arf
  class Error < StandardError; end
  class UnknownTypeError < Error; end
  class InvalidEncodingTypeError < Error; end
  class UnsupportedNestedUnionError < Error; end
  class DecodeFailedError < Error; end
  class UnknownMeessageError < Error; end
end
