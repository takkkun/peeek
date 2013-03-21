require 'peeek/hooks'

class Peeek
  class Supervisor

    # Create a supervisor for instance methods.
    #
    # @return [Peeek::Supervisor] a supervisor for instance methods
    def self.create_for_instance
      new(:method_added)
    end

    # Create a supervisor for singleton methods.
    #
    # @return [Peeek::Supervisor] a supervisor for singleton methods
    def self.create_for_singleton
      new(:singleton_method_added)
    end

    # Initialize the supervisor.
    #
    # @param [Symbol] callback_name name of the method that are called when
    #   methods was added to object of a hook
    def initialize(callback_name)
      @callback_name = callback_name
      @unlinked_hooks = Hooks.new
      @original_callbacks = {}
    end

    # Add hooks to target that are supervised.
    #
    # @param [Array<Peeek::Hook>] hooks hooks that are supervised
    def add(*hooks)
      @unlinked_hooks.push(*hooks)

      hooks.map(&:object).uniq.each do |object|
        @original_callbacks[object] = proceed(object) unless proceeded?(object)
      end

      self
    end
    alias << add

    # Clear the hooks and the objects that are supervising.
    def clear
      @unlinked_hooks.clear
      define_callbacks(@original_callbacks).clear
      self
    end

    # Run process while circumvent supervision.
    #
    # @yield any process that want to run while circumvent supervision
    def circumvent(&process)
      current_callbacks = @original_callbacks.keys.map do |object|
        [object, object.method(@callback_name)]
      end

      define_callbacks(@original_callbacks)

      begin
        @unlinked_hooks.circumvent(&process)
      ensure
        define_callbacks(Hash[current_callbacks])
      end
    end

    private

    def proceeded?(object)
      !!@original_callbacks[object]
    end

    def proceed(object)
      supervisor = self
      unlinked_hooks = @unlinked_hooks
      original_callbacks = @original_callbacks

      object.method(@callback_name).tap do |original_callback|
        define_callback(object) do |method_name|
          hook = unlinked_hooks.get(self, method_name)

          if hook
            unlinked_hooks.delete(hook)

            unless unlinked_hooks.get(self)
              original_callback = original_callbacks.delete(self)
              supervisor.__send__(:define_callback, self, &original_callback)
            end

            hook.link
          end

          original_callback[method_name]
        end
      end
    end

    def define_callback(object, &proc)
      object.singleton_class.__send__(:define_method, @callback_name, &proc)
    end

    def define_callbacks(callbacks)
      callbacks.each do |object, callback|
        define_callback(object, &callback)
      end
    end

  end
end
