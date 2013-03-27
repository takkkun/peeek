require 'peeek/hook/linker'

class Peeek
  class Hook
    class Instance < Linker

      # @attribute [r] method_prefix
      # @return [String] method prefix for instance method. return always "#"
      def method_prefix
        '#'
      end

      # Determine if the instance method is defined in the object.
      #
      # @return whether the instance method is defined in the object
      def defined?
        @object.method_defined?(@method_name)
      end

      # Link the hook to the instance method.
      def link
        @object.instance_method(@method_name).tap do |original_method|
          define_method do |*args|
            yield caller, self, original_method.bind(self), args
          end
        end
      end

      # Unlink the hook from the instance method.
      def unlink(original_method)
        define_method(original_method)
      end

    end
  end
end
