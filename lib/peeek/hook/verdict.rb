class Peeek
  class Hook
    module Verdict
      private

      # Determine if an object is a module or a class.
      #
      # @param [Module, Class, Object] object an object
      # @return whether an object is a module or a class
      def any_module?(object)
        object.class == Module || object.class == Class
      end

      # Determine if an object is an instance of any class.
      #
      # @param [Module, Class, Object] object an object
      # @return whether an object is an instance of any class
      def any_instance?(object)
        !any_module?(object)
      end

    end
  end
end
