class Peeek
  class UnlinkedHooks < Array

    def initialize(callback_name)
      super()
      @callback_name = callback_name
      @original_callbacks = {}
    end

    def get(object, method_name)
      find { |hook| hook.object == object && hook.method_name == method_name }
    end

    #
    def clear
      super

      @original_callbacks.each do |object, original_callback|
        define_callback(object, &original_callback)
      end

      @original_callbacks.clear
    end

    # @param [Object] object
    def control(object)
      unlinked_hooks = self

      @original_callbacks[object] = object.method(@callback_name).tap do |original_callback|
        define_callback(object) do |method_name|
          unlinked_hook = unlinked_hooks.get(self, method_name)
          unlinked_hooks.delete(unlinked_hook).link if unlinked_hook
          original_callback[method_name]
        end
      end
    end

    # @param [Object] object
    def controlled?(object)
      !!@original_callbacks[object]
    end

    private

    def define_callback(object, &proc)
      object.singleton_class.__send__(:define_method, @callback_name, &proc)
    end
  end
end
