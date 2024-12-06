# frozen_string_literal: true

module Arf
  module RPC
    MESSAGE_KIND_INVALID         = 0x00
    MESSAGE_KIND_REQUEST         = 0x01
    MESSAGE_KIND_RESPONSE        = 0x02
    MESSAGE_KIND_START_STREAM    = 0x03
    MESSAGE_KIND_STREAM_ITEM     = 0x04
    MESSAGE_KIND_STREAM_METADATA = 0x05
    MESSAGE_KIND_END_STREAM      = 0x06
    MESSAGE_KIND_STREAM_ERROR    = 0x07

    MESSAGE_KIND_FROM_BYTE = {
      MESSAGE_KIND_INVALID => :invalid,
      MESSAGE_KIND_REQUEST => :request,
      MESSAGE_KIND_RESPONSE => :response,
      MESSAGE_KIND_START_STREAM => :start_stream,
      MESSAGE_KIND_STREAM_ITEM => :stream_item,
      MESSAGE_KIND_STREAM_METADATA => :stream_metadata,
      MESSAGE_KIND_END_STREAM => :end_stream,
      MESSAGE_KIND_STREAM_ERROR => :stream_error
    }.freeze

    MESSAGE_KIND_FROM_SYMBOL = MESSAGE_KIND_FROM_BYTE.to_a.to_h(&:reverse)
  end
end
