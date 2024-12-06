# frozen_string_literal: true

module Arf
  module Status
    OK                  = 0
    CANCELLED           = 1
    UNKNOWN             = 2
    INVALID_ARGUMENT    = 3
    DEADLINE_EXCEEDED   = 4
    NOT_FOUND           = 5
    ALREADY_EXISTS      = 6
    PERMISSION_DENIED   = 7
    RESOURCE_EXHAUSTED  = 8
    FAILED_PRECONDITION = 9
    ABORTED             = 10
    OUT_OF_RANGE        = 11
    UNIMPLEMENTED       = 12
    INTERNAL_ERROR      = 13
    UNAVAILABLE         = 14
    DATA_LOSS           = 15
    UNAUTHENTICATED     = 16

    TO_SYMBOL = {
      OK => :ok,
      CANCELLED => :cancelled,
      UNKNOWN => :unknown,
      INVALID_ARGUMENT => :invalid_argument,
      DEADLINE_EXCEEDED => :deadline_exceeded,
      NOT_FOUND => :not_found,
      ALREADY_EXISTS => :already_exists,
      PERMISSION_DENIED => :permission_denied,
      RESOURCE_EXHAUSTED => :resource_exhausted,
      FAILED_PRECONDITION => :failed_precondition,
      ABORTED => :aborted,
      OUT_OF_RANGE => :out_of_range,
      UNIMPLEMENTED => :unimplemented,
      INTERNAL_ERROR => :internal_error,
      UNAVAILABLE => :unavailable,
      DATA_LOSS => :data_loss,
      UNAUTHENTICATED => :unauthenticated
    }.freeze

    FROM_SYMBOL = TO_SYMBOL.to_a.to_h(&:reverse)

    STATUS_TEXT = {
      ok: "OK",
      cancelled: "Cancelled",
      unknown: "Unknown",
      invalid_argument: "Invalid Argument",
      deadline_exceeded: "Deadline Exceeded",
      not_found: "Not Found",
      already_exists: "Already Exists",
      permission_denied: "Permission Denied",
      resource_exhausted: "Resource Exhausted",
      failed_precondition: "Failed Precondition",
      aborted: "Aborted",
      out_of_range: "Out of Range",
      unimplemented: "Unimplemented",
      internal_error: "Internal Error",
      unavailable: "Unavailable",
      data_loss: "Data Loss",
      unauthenticated: "Unauthenticated"
    }.freeze

    class BadStatus < Arf::Error
      attr_reader :code

      def initialize(code, msg = nil)
        @code = code.is_a?(Symbol) ? code : TO_SYMBOL[code]
        @msg = msg || STATUS_TEXT[@code] || "Unknown status"
        super(@msg)
      end
    end
  end
end
