require 'peeek/hook'

class Peeek
  class Hook
    class Specifier

      # Parse a string as hook specifier.
      #
      # @param [String] string string to parse as hook specifier
      # @return [Peeek::Hook::Specifier] a hook specifier
      def self.parse(string)
        method_prefixes = METHOD_PREFIXES.sort_by(&:length).reverse.map do |method_prefix|
          index = string.rindex(method_prefix)
          priority = index ? [index + method_prefix.length, method_prefix.length] : nil
          [method_prefix, index, priority]
        end

        method_prefixes = method_prefixes.select(&:last)
        raise ArgumentError, "method name that is target of hook isn't specified in #{string.inspect}" if method_prefixes.empty?
        method_prefix, index = method_prefixes.max_by(&:last)
        method_prefix_range = index..(index + method_prefix.length - 1)

        object_name = string[0..(method_prefix_range.begin - 1)]
        method_name = string[(method_prefix_range.end + 1)..-1].to_sym
        new(object_name, method_prefix, method_name)
      end

      # Initialize the hook specifier.
      #
      # @param [String] object_name object name
      # @param [String] method_prefix method prefix
      # @param [Symbol] method_name method name in the object
      def initialize(object_name, method_prefix, method_name)
        @object_name   = object_name
        @method_prefix = normalize_method_prefix(method_prefix)
        @method_name   = method_name
      end

      # @attribute [r] object_name
      # @return [String] object name
      attr_reader :object_name

      # @attribute [r] method_prefix
      # @return [String] method prefix
      attr_reader :method_prefix

      # @attribute [r] method_name
      # @return [Symbol] method name in the object
      attr_reader :method_name

      # @attribute [r] method_specifier
      # @return [String] method specifier in the object
      def method_specifier
        @method_prefix + @method_name.to_s
      end

      def to_s
        @object_name + method_specifier
      end

      def inspect
        "#<#{self.class} #{self}>"
      end

      def ==(other)
        self.class     == other.class         &&
        @object_name   == other.object_name   &&
        @method_prefix == other.method_prefix &&
        @method_name   == other.method_name
      end
      alias eql? ==

      def hash
        values = [@object_name, @method_prefix, @method_name]
        values.inject(self.class.hash) { |hash, value| (hash << 32) + value.hash }
      end

      private

      def normalize_method_prefix(method_prefix)
        case method_prefix
        when *INSTANCE_METHOD_PREFIXES
          Instance::METHOD_PREFIX
        when *SINGLETON_METHOD_PREFIXES
          Singleton::METHOD_PREFIX
        else
          *init, last = METHOD_PREFIXES.map(&:inspect)
          method_prefixes = [init * ', ', last] * ' or '
          raise ArgumentError, "invalid method prefix, #{method_prefixes} are valid"
        end
      end

    end
  end
end
