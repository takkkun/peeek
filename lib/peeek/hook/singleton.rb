require 'peeek/hook/linker'

class Peeek
  class Hook
    class Singleton < Linker

      # @attribute [r] method_prefix
      # @return [String] method prefix for singleton method. return always "."
      def method_prefix
        '.'
      end

      # Determine if the method is defined in the object.
      #
      # @return whether the method is defined in the object
      def defined?
        @object.respond_to?(@method_name, true)
      end

      # Link the hook to the method.
      def link
        @object.method(@method_name).tap do |original_method|
          define_method do |*args|
            yield caller, self, original_method, args
          end
        end
      end

      # Unlink the hook from the method.
      def unlink(original_method)
        define_method(&original_method)
      end

    end
  end
end
