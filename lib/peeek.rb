require 'peeek/version'
require 'peeek/hook'
require 'peeek/unlinked_hooks'
require 'peeek/calls'

class Peeek
  def self.capture(targets)
    raise ArgumentError unless block_given?

    peeek = new
    targets.each { |object, method_specs| peeek.establish(object, *method_specs) }

    begin
      yield
      Calls.new(peeek.hooks.inject([]) { |calls, hook| calls + hook.calls })
    ensure
      peeek.release
    end
  end

  def initialize
    @hooks = []
    @instance_unlinked_hooks = UnlinkedHooks.new(:method_added)
    @singleton_unlinked_hooks = UnlinkedHooks.new(:singleton_method_added)
  end

  attr_reader :hooks

  def establish(object, *method_specs, &process)
    method_specs.each do |method_spec|
      hook = Hook.create(object, method_spec, &process)

      if hook.defined?
        hook.link
      else
        unlinked_hooks = hook.is_a?(Hook::Instance) ? @instance_unlinked_hooks : @singleton_unlinked_hooks
        unlinked_hooks.control(object) unless unlinked_hooks.controlled?(object)
        unlinked_hooks << hook
      end

      @hooks << hook
    end
  end

  def release
    @hooks.each(&:unlink).each(&:clear).clear
    @instance_unlinked_hooks.clear
    @singleton_unlinked_hooks.clear
  end
end
