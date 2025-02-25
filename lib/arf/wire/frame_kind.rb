# frozen_string_literal: true

module Arf
  module Wire
    FRAME_KIND_HELLO  = 0x0
    FRAME_KIND_PING           = 0x1
    FRAME_KIND_GO_AWAY        = 0x2
    FRAME_KIND_MAKE_STREAM    = 0x3
    FRAME_KIND_RESET_STREAM   = 0x4
    FRAME_KIND_DATA           = 0x5

    FRAME_TO_SYMBOL = {
      FRAME_KIND_HELLO => :hello,
      FRAME_KIND_PING => :ping,
      FRAME_KIND_GO_AWAY => :go_away,
      FRAME_KIND_MAKE_STREAM => :make_stream,
      FRAME_KIND_RESET_STREAM => :reset_stream,
      FRAME_KIND_DATA => :data
    }.freeze

    SYMBOL_TO_FRAME = FRAME_TO_SYMBOL.to_a.to_h(&:reverse)
  end
end
