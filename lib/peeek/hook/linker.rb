class Peeek
  class Hook
    class Linker
      @classes = []

      class << self

        # @attribute [r] classes
        # @scope class
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

    end
  end
end
