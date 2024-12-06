# frozen_string_literal: true

require_relative "types/coercion"
require_relative "types/base_type"
require_relative "types/array_type"
require_relative "types/map_type"
require_relative "types/streamer"
require_relative "types/in_out_stream"
require_relative "types/input_stream"
require_relative "types/output_stream"
require_relative "types/mixin"

module Arf
  module Types
    INTEGERS = %i[uint8 uint16 uint32 uint64 int8 int16 int32 int64].freeze
    FLOATS = %i[float32 float64].freeze
    OTHERS = %i[bool string bytes].freeze

    def self.try_const_get(mod, name)
      mod.const_get(name)
    rescue NameError
      nil
    end

    def self.lookup_type(mod, path, direction:)
      key = [mod, path.join("::"), direction]
      @lookup_cache ||= {}
      return @lookup_cache[key] if @lookup_cache.key? key

      v = if direction == :up
            lookup_type_up(mod, path)
          else
            lookup_type_down(mod, path)
          end

      @lookup_cache[key] = v
    end

    def self.lookup_type_up(mod, path)
      return mod if path.empty?

      key = path.first
      v = try_const_get(mod, key)
      if v
        lookup_type_down(v, path.tap(&:shift))
      elsif mod == Object
        nil
      else
        parent = mod.name.split("::").tap(&:pop).last
        return nil if parent.nil?

        v = try_const_get(mod, parent)
        return nil if v.nil?

        lookup_type_down(v, path)
      end
    end

    def self.lookup_type_down(mod, path)
      return mod if path.empty?

      key = path.first
      v = try_const_get(mod, key)
      return nil unless v

      lookup_type_down(v, path.tap(&:shift))
    end
  end
end
