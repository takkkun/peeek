require 'peeek/hook'

class Peeek
  class CLI
    class BadHookSpecifier < StandardError; end

    class HookSpecifiers < Hash

      HOOK_SPEC_REGEXP = begin
                           method_prefixes = Hook::METHOD_PREFIXES.map(&Regexp.method(:quote))
                           /^([^\s\.;]+)(#{method_prefixes * '|'})([^\s\.:;]+)$/
                         end

      # Add a hook specifier.
      #
      # @param [String] hook_spec a hook specifier
      def add(hook_spec)
        object_name, method_spec = extract(hook_spec)
        method_specs = (self[object_name] ||= [])
        method_specs << method_spec unless method_specs.include?(method_spec)
        self
      end
      alias << add

      # Materialize the hook specifiers.
      #
      # @param [Binding] binding context that evaluates the object names as
      #   expression
      # @return [Hash{Module, Class, Object => Array<String>}] materialized hook
      #   specifiers
      def materialize(binding)
        Hash[map { |object_name, method_specs| [materialize_by(object_name, binding), method_specs] }]
      end

      private

      def extract(hook_spec)
        method_prefixes = Hook::METHOD_PREFIXES.sort_by(&:length).reverse.map do |method_prefix|
          index = hook_spec.rindex(method_prefix)
          [method_prefix, method_prefix.length, index]
        end

        # Remove non-existent method prefixes. Namely, be target that the return
        # value of hook_spec.rindex is nil.
        method_prefixes.reject! { |method_prefix| method_prefix[2].nil? }
        raise BadHookSpecifier, "method name that is target of hook isn't specified in #{hook_spec}" if method_prefixes.empty?

        # Choose the method prefix longer, located further back in hook_spec.
        method_prefix, _, index = method_prefixes.max_by { |method_prefix| method_prefix[1..2] }
        method_prefix_range = index..(index + method_prefix.length - 1)

        object_name = hook_spec[0..(method_prefix_range.begin - 1)]
        method_name = hook_spec[(method_prefix_range.end + 1)..-1]
        [object_name, normalize_method_prefix(method_prefix) + method_name]
      end

      def normalize_method_prefix(method_prefix)
        case method_prefix
        when *Hook::INSTANCE_METHOD_PREFIXES  then Hook::Instance::METHOD_PREFIX
        when *Hook::SINGLETON_METHOD_PREFIXES then Hook::Singleton::METHOD_PREFIX
                                              else ''
        end
      end

      def materialize_by(expr, binding)
        type = binding.eval("defined? #{expr}")
        raise BadHookSpecifier, "#{expr} is undefined" if type.nil?
        raise BadHookSpecifier, "#{expr} should be a constant or a global variable" unless type == 'constant' || type == 'global-variable'
        binding.eval(expr)
      end

    end
  end
end
