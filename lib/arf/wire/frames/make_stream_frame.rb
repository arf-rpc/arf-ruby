# frozen_string_literal: true

module Arf
  module Wire
    class MakeStreamFrame < BaseFrame
      frame_kind :make_stream
      value_size 0
      wants_stream_id!

      def from_frame(fr)
        @stream_id = fr.stream_id
      end
    end
  end
end
