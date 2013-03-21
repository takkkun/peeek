class Peeek
  class Hooks < Array

    # Get a hook by an object and a method name.
    #
    # @param [Module, Class, Object] object object of a hook to get
    # @param [Symbol] method_name method name of a hook to get. get only the
    #   hook by the object if omitted
    # @return [Peeek::Hook] a hook to be got
    # @return [nil] if don't exist a hook that correspond to the object and the
    #   method name
    def get(object, method_name = nil)
      if method_name.nil?
        find { |hook| hook.object == object }
      else
        find { |hook| hook.object == object && hook.method_name == method_name }
      end
    end

    # Clear the hooks.
    def clear
      each { |hook| hook.unlink.clear }
      super
    end

    # Run process while circumvent the hooks.
    #
    # @yield any process that want to run while circumvent the hooks
    def circumvent
      raise ArgumentError, 'block not supplied' unless block_given?

      linked_hooks = select(&:linked?).each(&:unlink)

      begin
        yield
      ensure
        linked_hooks.each(&:link)
      end
    end

  end
end
