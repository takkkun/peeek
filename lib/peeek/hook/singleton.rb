require 'peeek/hook/base'

class Peeek
  module Hook
    class Singleton < Base
      @method_prefix = '.'

      def defined?
        object.respond_to?(method_name, true)
      end

      protected

      def enforce
        call = method(:call)

        object.method(method_name).tap do |original_method|
          define_method do |*args|
            call[self, caller, args]
            original_method[*args]
          end
        end
      end

      def revert(original_method)
        define_method(&original_method)
      end
    end
  end
end
