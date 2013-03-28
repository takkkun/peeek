require 'peeek/hook/linker'

class Peeek
  class Hook
    class Instance < Linker
      METHOD_PREFIX = '#'.freeze

      # @attribute [r] method_prefix
      # @return [String] method prefix for instance method. return always "#"
      def method_prefix
        METHOD_PREFIX
      end

      # Determine if the instance method is defined in the object.
      #
      # @return whether the instance method is defined in the object
      def defined?
        @object.method_defined?(@method_name)
      end

      # Link the hook to the instance method.
      #
      # @yield [backtrace, receiver, args] callback for hook
      # @yieldparam [Array<String>] backtrace backtrace the call occurred
      # @yieldparam [Object] receiver object that received the call
      # @yieldparam [Array] args arguments at the call
      # @yieldreturn [Object] return value of the original method
      # @return [UnboundMethod] the original method
      def link
        raise ArgumentError, 'block not supplied' unless block_given?
        original_method = @object.instance_method(@method_name)
        define_method { |*args| yield caller, self, args }
        original_method
      end

      # Unlink the hook from the instance method.
      #
      # @param [UnboundMethod] original_method original method
      def unlink(original_method)
        define_method(original_method)
      end

    end
  end
end
