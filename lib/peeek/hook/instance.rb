require 'peeek/hook/base'

class Peeek
  module Hook
    class Instance < Base
      @method_prefix = '#'

      def initialize(object, method_name)
        super
        raise ArgumentError, '' unless Hook.module?(object)
      end

      def defined?
        object.method_defined?(method_name)
      end

      protected

      def enforce
        call = method(:call)

        object.instance_method(method_name).tap do |original_method|
          define_method do |*args|
            call[self, caller, args]
            original_method.bind(self)[*args]
          end
        end
      end

      def revert(original_method)
        define_method(original_method)
      end
    end
  end
end
