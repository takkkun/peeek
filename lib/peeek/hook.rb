require 'peeek/hook/instance'
require 'peeek/hook/singleton'
require 'peeek/hook/verdict'
require 'peeek/call'
require 'peeek/calls'

class Peeek
  class Hook
    extend Verdict
    include Verdict

    # Create a hook to method of an object. The hook can apply to a instance
    # method or a singleton method.
    #
    # @example Hook to an instance method
    #   Peeek::Hook.create(IO, '#puts')
    #     # => #<Peeek::Hook IO#puts>
    #
    #   # Hook implicitly to the instance method if the object is a module or
    #   # a class.
    #   Peeek::Hook.create(IO, :puts)
    #     # => #<Peeek::Hook IO#puts>
    #
    #   # Can't hook to the instance method if the object is an instance of any
    #   # class.
    #   Peeek::Hook.create($stdout, '#puts')
    #     # => raise #<ArgumentError: can't create a hook of instance method to an instance of any class>
    #
    # @example Hook to an singleton method
    #   Peeek::Hook.create($stdout, '.puts')
    #     # => #<Peeek::Hook #<IO:<STDOUT>>.puts>
    #
    #   # hook implicitly to the singleton method if the object is an instance
    #   # of any class.
    #   Peeek::Hook.create($stdout, :puts)
    #     # => #<Peeek::Hook #<IO:<STDOUT>>.puts>
    #
    # @param [Module, Class, Object] object a target object that hook
    # @param [String, Symbol] method_spec method specification of the object
    # @yield process a call to the method. give optionally
    # @yieldparam [Peeek::Call] a call to the method
    # @return [Peeek::Hook] a hook to the method of the object
    def self.create(object, method_spec, &process)
      linker_class, method_name = parse(method_spec)
      linker_class = any_module?(object) ? Instance : Singleton unless linker_class
      new(object, method_name, linker_class, &process)
    end

    # Initialize the hook.
    #
    # @param [Module, Class, Object] object a target object that hook
    # @param [Symbol] method_name method name of the object
    # @param [Class] linker_class class of an object to link the hook
    # @yield process a call to the method. give optionally
    # @yieldparam [Peeek::Call] a call to the method
    def initialize(object, method_name, linker_class, &process)
      raise ArgumentError, "invalid as linker class, #{Linker.classes.join(' or ')} are valid" unless Linker.classes.include?(linker_class)
      @object = object
      @method_name = method_name
      @linker = linker_class.new(object, method_name)
      @process = process
      @calls = Calls.new
      raise ArgumentError, "can't create a hook of instance method to an instance of any class" if any_instance?(object) and instance?
    end

    # @attribute [r] object
    # @return [Module, Class, Object] a target object that hook
    attr_reader :object

    # @attribute [r] method_name
    # @return [Symbol] method name of the object
    attr_reader :method_name

    # @attribute [r] calls
    # @return [Peeek::Calls] calls to the method that the hook captured
    attr_reader :calls

    # Determine if the hook to an instance method.
    #
    # @return whether the hook to an instance method
    def instance?
      @linker.is_a?(Instance)
    end

    # Determine if the hook to a singleton method.
    #
    # @return whether the hook to a singleton method
    def singleton?
      @linker.is_a?(Singleton)
    end

    # Determine if the method is defined in the object
    #
    # @return whether the method is defined in the object
    def defined?
      @linker.defined?
    end

    # Determine if the hook is linked to the method
    #
    # @return whether the hook is linked to the method
    def linked?
      instance_variable_defined?(:@original_method)
    end

    # Link the hook to the method.
    def link
      @original_method = @linker.link(&method(:call)) unless linked?
      self
    end

    # Unlink the hook from the method.
    def unlink
      if linked?
        @linker.unlink(@original_method)
        remove_instance_variable(:@original_method)
      end

      self
    end

    # Clear calls.
    #
    # @see #calls
    def clear
      @calls.clear
      self
    end

    def to_s
      @object.inspect + @linker.method_prefix + @method_name.to_s
    end

    def inspect
      state = []
      state << 'linked' if linked?
      state_string = state.empty? ? '' : " (#{state * ', '})"
      "#<#{self.class} #{self}#{state_string}>"
    end

    private

    INSTANCE_METHOD_PREFIXES  = %w(#)
    SINGLETON_METHOD_PREFIXES = %w(. .# ::)
    METHOD_PREFIXES           = INSTANCE_METHOD_PREFIXES + SINGLETON_METHOD_PREFIXES

    def self.parse(method_spec)
      method_spec = method_spec.to_s

      method_prefix = METHOD_PREFIXES.sort_by(&:length).reverse.find do |method_prefix|
        method_spec.start_with?(method_prefix)
      end

      return nil, method_spec.to_sym unless method_prefix

      linker_class = INSTANCE_METHOD_PREFIXES.include?(method_prefix) ? Instance : Singleton
      method_name = method_spec.to_s.sub(/^#{Regexp.quote(method_prefix || '')}/, '').to_sym
      [linker_class, method_name]
    end
    singleton_class.instance_eval { private :parse }

    def call(backtrace, receiver, args)
      method = @original_method.is_a?(UnboundMethod) ? @original_method.bind(receiver) : @original_method
      result = Call::ReturnValue.new(method[*args]) rescue Call::Exception.new($!)
      call = Call.new(self, backtrace, receiver, args, result)
      @calls << call
      @process[call] if @process
      raise call.exception if call.raised?
      call.return_value
    end

  end
end
