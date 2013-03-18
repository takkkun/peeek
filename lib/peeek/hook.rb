require 'peeek/hook/instance'
require 'peeek/hook/singleton'

class Peeek
  module Hook
    INSTANCE_METHOD_PREFIXES  = %w(#)
    SINGLETON_METHOD_PREFIXES = %w(. .# ::)
    METHOD_PREFIXES           = INSTANCE_METHOD_PREFIXES + SINGLETON_METHOD_PREFIXES

    # @param [Object] object
    # @param [String, Symbol] method_spec
    # @return [Peeek::Hook::Instance, Peeek::Hook::Singleton]
    def self.create(object, method_spec)
      hook_class, method_name = parse(method_spec)
      hook_class = module?(object) ? Instance : Singleton unless hook_class
      hook_class.new(object, method_name)
    end

    #
    def self.disable_detection
      Instance.disable_detection
      Singleton.disable_detection
    end

    def self.module?(object)
      object.class == Module || object.class == Class
    end

    private

    def self.parse(method_spec)
      method_spec = method_spec.to_s

      method_prefix = METHOD_PREFIXES.sort_by(&:length).reverse.find do |method_prefix|
        method_spec.start_with?(method_prefix)
      end

      return nil, method_spec.to_sym unless method_prefix

      hook_class = INSTANCE_METHOD_PREFIXES.include?(method_prefix) ? Instance : Singleton
      method_name = method_spec.to_s.sub(/^#{Regexp.quote(method_prefix || '')}/, '').to_sym
      [hook_class, method_name]
    end
  end
end
