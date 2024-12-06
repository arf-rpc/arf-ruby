# frozen_string_literal: true

module Arf
  module RPC
    class Struct
      include Arf::Types::Mixin

      def self.arf_struct_id(v = nil)
        return @arf_struct_id if v.nil?

        @arf_struct_id = v
        Arf::Proto::Registry.register! self
        v
      end

      def self.validate_subclass(type, v)
        cls = find_type(type)
        if cls.ancestors.include?(Arf::RPC::Enum)
          !cls.to_i(v).nil?
        else
          v.is_a?(cls) || v.is_a?(Hash)
        end
      end

      def self.validator_for_type(type, optional:)
        validator = if ::Arf::Types::INTEGERS.include?(type)
                      ->(v) { v.is_a?(Float) || v.is_a?(Integer) }
                    elsif ::Arf::Types::FLOATS.include?(type)
                      ->(v) { v.is_a?(Float) || v.is_a?(Integer) }
                    elsif type == :string
                      ->(v) { v.is_a?(String) }
                    elsif type == :bool
                      ->(v) { v.is_a?(TrueClass) || v.is_a?(FalseClass) }
                    elsif type == :bytes
                      ->(v) { v.is_a?(StringIO) || v.is_a?(String) }
                    elsif type.is_a? MapType
                      ->(v) { v.is_a? Hash }
                    elsif type.is_a? ArrayType
                      ->(v) { v.is_a? Array }
                    elsif type.is_a? String
                      # Validation for nested classes must be done at time of assignment
                      # since we can't rely on it being available during the field's
                      # definition.
                      ->(v) { validate_subclass(type, v) }
                    elsif type.ancestors.include?(Arf::RPC::Enum)
                      ->(v) { !type.to_i(v).nil? }
                    else
                      raise ArgumentError, "Invalid type #{type.inspect} (#{type.class.name})"
                    end

        if optional
          ->(v) { v.nil? || validator.call(v) }
        else
          validator
        end
      end

      def self.default_for_type(type)
        if ::Arf::Types::INTEGERS.include?(type)
          0
        elsif ::Arf::Types::FLOATS.include?(type)
          0.0
        elsif type == :string
          ""
        elsif type == :bool
          false
        elsif type == :bytes
          ""
        elsif type.is_a? MapType
          {}
        elsif type.is_a? ArrayType
          []
        elsif type.is_a? String
          # Validation for nested classes must be done at time of assignment
          # since we can't rely on it being available during the field's
          # definition.
          cls = find_type(type)
          if cls.ancestors.include?(Arf::RPC::Enum)
            default_for_type(cls)
          else
            cls.new
          end
        elsif type.ancestors.include?(Arf::RPC::Enum)
          type.options.keys.first
        else
          raise ArgumentError, "Invalid type #{type.inspect} (#{type.class.name})"
        end
      end

      def self.field(id, name, type, optional: false)
        @fields ||= []
        @fields << { id:, name: name.to_s, type:, optional: }
        attr_reader(name)

        validator = validator_for_type(type, optional:)
        define_method("#{name}=") do |v|
          unless validator.call(v)
            raise ArgumentError, "Invalid value for #{self.class.name}.#{name}, type #{type}: #{v.inspect}"
          end

          v = _coerce(v, type)

          instance_variable_set("@__arf_union_set_id", id) if union? && !@skip_union_setter
          instance_variable_set("@#{name}", v)
        end
      end

      def self.all_fields
        @all_fields ||= @fields
          .map do |v|
            next v unless v[:id] == :union

            find_type(v[:type])
              .all_fields
              .map { _1.merge(via: v[:name]) }
          end
          .flatten
      end

      def self.fields = @fields || []
      def self.field_by_id(id) = @fields.find { _1[:id] == id }
      def self.field_by_name(name) = name.to_s.then { |n| @fields.find { _1[:name] == n } }

      def self.union!
        @union = true
        attr_reader(:__arf_union_set_id)
      end

      def self.union? = @union || false

      def arf_struct_id = self.class.arf_struct_id
      def union? = self.class.union?

      def initialize(**kwargs)
        cls = self.class
        kwargs.each_pair do |k, v|
          field = cls.field_by_name(k)
          raise ArgumentError, "#{cls.name}: Unknown field #{k}" unless field

          v = _coerce(v, field[:type])
          send("#{k}=", v)
        end

        @skip_union_setter = true
        # Initialize missing variables
        cls.fields.each do |f|
          next if f[:optional]

          send("#{f[:name]}=", cls.default_for_type(f[:type])) if instance_variable_get("@#{f[:name]}").nil?
        end

        if union? && __arf_union_set_id.nil?
          @skip_union_setter = false
          # Set the first field
          f = cls.fields.first
          send("#{f[:name]}=", cls.default_for_type(f[:type]))
        end
      ensure
        @skip_union_setter = false
      end

      def _coerce(value, type)
        cls = self.class
        case type
        when String
          type = cls.find_type(type)
          if type.ancestors.include?(Arf::RPC::Enum)
            type.to_sym(value)
          else
            case value
            when Hash then type.new(**value)
            when type then value
            else
              raise ArgumentError,
                    "Cannot initialize #{type} with #{value.inspect} (#{value.class}). Did you mean to use a Hash?"
            end
          end
        when ArrayType
          type.coerce(value)
        when MapType
          type.coerce(value)
        else
          ::Arf::Types.coerce_value(value, type)
        end
      end

      def decode_fields(fields)
        fields.each_pair do |id, value|
          meta = self.class.all_fields.find { _1[:id] == id }
          unless meta
            puts "WARNING: Skipping field ID #{id} without matching ID on target type #{self.class.name}"
            next
          end
          if meta[:via]
            union_field = self.class.all_fields.find { _1[:id] == value[:id] }
            instance_variable_get("@#{meta[:via]}")
              .send("#{union_field[:name]}=", value[:value])
            next
          end

          next if meta[:optional] && value.nil?

          instance_variable_set("@#{meta[:name]}", _coerce(value, meta[:type]))
        end
        self
      end

      def ==(other)
        return false unless other.is_a? self.class

        return eq_union(other) if union?

        eq_struct(other)
      end

      def eq_struct(other)
        self.class.fields.each do |v|
          return false unless send(v[:name]) == other.send(v[:name])
        end
        true
      end

      def eq_union(other)
        return false unless other.__arf_union_set_id == __arf_union_set_id

        self.class.fields.each do |v|
          return false if instance_variable_get("@#{v[:name]}") != other.instance_variable_get("@#{v[:name]}")
        end

        true
      end

      def hashify(value)
        case value
        when nil then nil
        when Arf::RPC::Struct then value.to_h
        when Array then value.map { hashify(_1) }
        when Hash then value.transform_values { |v| hashify(v) }
        else value
        end
      end

      def to_h
        if union?
          set = self.class.fields.find { _1[:id] == __arf_union_set_id }
          return { set[:name] => hashify(instance_variable_get("@#{set[:name]}")) }
        end

        self.class.fields
          .to_h { |f| [f[:name], hashify(instance_variable_get("@#{f[:name]}"))] }
          .compact
      end
    end
  end
end
