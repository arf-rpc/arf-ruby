# frozen_string_literal: true

module Arf
  module Wire
    ERROR_CODE_NO_ERROR             = 0x00
    ERROR_CODE_PROTOCOL_ERROR       = 0x01
    ERROR_CODE_INTERNAL_ERROR       = 0x02
    ERROR_CODE_STREAM_CLOSED        = 0x03
    ERROR_CODE_FRAME_SIZE_ERROR     = 0x04
    ERROR_CODE_REFUSED_STREAM       = 0x05
    ERROR_CODE_CANCEL               = 0x06
    ERROR_CODE_COMPRESSION_ERROR    = 0x07
    ERROR_CODE_ENHANCE_YOUR_CALM    = 0x08
    ERROR_CODE_INADEQUATE_SECURITY  = 0x09

    ERROR_TO_STRING = {
      ERROR_CODE_NO_ERROR => "No error",
      ERROR_CODE_PROTOCOL_ERROR => "Protocol Error",
      ERROR_CODE_INTERNAL_ERROR => "Internal Error",
      ERROR_CODE_STREAM_CLOSED => "Stream Closed",
      ERROR_CODE_FRAME_SIZE_ERROR => "Frame Size Error",
      ERROR_CODE_REFUSED_STREAM => "Refused Stream",
      ERROR_CODE_CANCEL => "Cancel",
      ERROR_CODE_COMPRESSION_ERROR => "Compression Error",
      ERROR_CODE_ENHANCE_YOUR_CALM => "Enhance Your Calm",
      ERROR_CODE_INADEQUATE_SECURITY => "Inadequate Security"
    }.freeze

    def self.error_code_to_string(code)
      return ERROR_TO_STRING[code] if ERROR_TO_STRING.key? code

      "Unknown error 0x#{code.to_s(16)}"
    end
  end
end
