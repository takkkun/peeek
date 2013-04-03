require 'peeek/version'
require 'peeek/hook'
require 'peeek/hooks'
require 'peeek/supervisor'
require 'peeek/calls'

class Peeek

  # @attribute [r] global
  # @return [Peeek] the global Peeek object
  def self.global
    @global ||= new
  end

  # @attribute [r] current
  # @return [Peeek] the current Peeek object
  #
  # @see Peeek.local
  def self.current
    @current ||= global
  end

  # Run process to switch to a local Peeek object from the current Peeek
  # object. The local Peeek object doesn't inherit the registered hooks and
  # supervision from the current Peeek object. The current Peeek object reverts
  # after ran the process.
  #
  # @yield any process that want to run to switch
  def self.local
    raise ArgumentError, 'block not supplied' unless block_given?

    old = current
    @current = new

    old.circumvent do
      begin
        yield
      ensure
        current.release
        @current = old
      end
    end
  end

  # Capture all calls to hook targets.
  #
  # @param [Hash{Module, Class, Object => String, Array<String>, Symbol, Array<Symbol>}]
  #   object_and_method_specs an object and method specification(s) that be
  #                           target of hook
  # @yield any process that want to run to capture
  # @return [Peeek::Calls] calls that were captured in the block
  def self.capture(object_and_method_specs)
    raise ArgumentError, 'block not supplied' unless block_given?

    local do
      object_and_method_specs.each { |object, method_specs| current.hook(object, *method_specs) }
      yield
      current.calls
    end
  end

  # Initialize the Peeek object.
  def initialize
    @hooks = Hooks.new
    @instance_supervisor = Supervisor.create_for_instance
    @singleton_supervisor = Supervisor.create_for_singleton
  end

  # @attribute [r] hooks
  # @return [Peeek::Hooks] the registered hooks
  attr_reader :hooks

  # @attribute [r] calls
  # @return [Peeek::Calls] calls to the methods that the registered hooks
  #   captured
  def calls
    Calls.new(@hooks.map(&:calls).inject([], &:+))
  end

  # Register a hook to methods of an object.
  #
  # @param [Module, Class, Object] object a target object that hook
  # @param [Array<String>, Array<Symbol>] method_specs method specifications of
  #   the object. see also examples of {Peeek::Hook.create}
  # @yield [call] process a call to the methods. give optionally
  # @yieldparam [Peeek::Call] call a call to the methods
  # @return [Peeek::Hooks] registered hooks at calling
  #
  # @see Peeek::Hook.create
  def hook(object, *method_specs, &process)
    hooks = method_specs.map do |method_spec|
      Hook.create(object, method_spec, &process).tap do |hook|
        if hook.defined?
          hook.link
        elsif hook.instance?
          @instance_supervisor << hook
        elsif hook.singleton?
          @singleton_supervisor << hook
        end
      end
    end

    @hooks.push(*hooks)
    Hooks.new(hooks)
  end

  # Release the registered hooks and supervision.
  def release
    @hooks.clear
    @instance_supervisor.clear
    @singleton_supervisor.clear
    self
  end

  # Run process while circumvent the registered hooks and supervision.
  #
  # @yield any process that want to run while circumvent the registered hooks
  #   and supervision
  def circumvent(&process)
    raise ArgumentError, 'block not supplied' unless block_given?

    @singleton_supervisor.circumvent do
      @instance_supervisor.circumvent do
        @hooks.circumvent(&process)
      end
    end
  end

  module Readily

    # Register a hook to methods of self to the current Peeek object.
    #
    # @param [Array<String>, Array<Symbol>] method_specs method specifications
    #   of the object. see also examples of {Peeek::Hook.create}
    # @yield [call] process a call to the methods. give optionally
    # @yieldparam [Peeek::Call] call a call to the methods
    #
    # @see Peeek#hook
    def peeek(*method_specs, &process)
      Peeek.current.hook(self, *method_specs, &process)
    end

  end

  Object.__send__(:include, Readily)

end
