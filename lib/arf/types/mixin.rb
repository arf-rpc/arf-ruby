# frozen_string_literal: true

module Arf
  module Types
    module Mixin
      MapType = ::Arf::Types::MapType
      ArrayType = ::Arf::Types::ArrayType
      InputStream = ::Arf::Types::InputStream
      OutputStream = ::Arf::Types::OutputStream
      InOutStream = ::Arf::Types::InOutStream
      Streamer = ::Arf::Types::Streamer

      module ClassMethods
        def find_type(named)
          components = named.split("::")
          if components.first.empty?
            # Look from the root, starting at Object
            ::Arf::Types.lookup_type(Object, components[1...], direction: :down)
          else
            # Look from local scope upwards
            ::Arf::Types.lookup_type(self, components, direction: :up)
          end
        end
      end

      def self.included(base) = base.extend(ClassMethods)
    end
  end
end
