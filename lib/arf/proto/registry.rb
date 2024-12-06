# frozen_string_literal: true

module Arf
  module Proto
    module Registry
      def self.register!(cls)
        @structs ||= {}
        id = cls.arf_struct_id
        fields = Proto.fields_from_struct(cls)
        @structs[id] = {
          id:,
          fields:,
          type: cls
        }
      end

      def self.reset!
        @structs = {}
      end

      def self.find(id)
        @structs ||= {}
        @structs[id]
      end
    end
  end
end
