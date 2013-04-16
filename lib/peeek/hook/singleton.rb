require 'peeek/hook/linker'

class Peeek
  class Hook
    class Singleton < Linker
      METHOD_PREFIX = '.'.freeze

      # @attribute [r] method_prefix
      # @return [String] method prefix for singleton method. return always "."
      def method_prefix
        METHOD_PREFIX
      end

      # @attribute [r] target_method
      # @return [Method] the method of the object
      def target_method
        @object.method(@method_name)
      end

      # Determine if the method is defined in the object.
      #
      # @return whether the method is defined in the object
      def defined?
        @object.respond_to?(@method_name, true)
      end

      # Link the hook to the method.
      #
      # @yield [backtrace, receiver, args] callback for hook
      # @yieldparam [Array<String>] backtrace backtrace the call occurred
      # @yieldparam [Object] receiver object that received the call
      # @yieldparam [Array] args arguments at the call
      # @yieldreturn [Object] return value of the original method
      def link
        raise ArgumentError, 'block not supplied' unless block_given?
        define_method { |*args| yield caller, self, args }
      end

      # Unlink the hook from the method.
      #
      # @param [Method] original_method original method
      def unlink(original_method)
        define_method(&original_method)
      end

      private

      def define_method(&block)
        singleton_class = class << @object; self end
        singleton_class.__send__(:define_method, @method_name, &block)
      end

    end
  end
end
