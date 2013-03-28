require 'peeek/hook'

class Peeek
  class Hook
    class Linker
      @classes = []

      class << self

        # @attribute [r] classes
        # @return [Array<Class>] classes valid as linker
        attr_reader :classes

      end

      def self.inherited(klass)
        @classes << klass
      end

      # Initialize the linker.
      #
      # @param [Module, Class, Object] object a target object that hook
      # @param [Symbol] method_name method name of the object
      def initialize(object, method_name)
        @object = object
        @method_name = method_name
      end

      protected

      def define_method(*args, &block)
        object = Hook.any_instance?(@object) ? @object.singleton_class : @object
        object.__send__(:define_method, @method_name, *args, &block)
      end

    end
  end
end
