require 'peeek/call'
require 'peeek/calls'

class Peeek
  module Hook
    class Base
      @method_prefix = ''

      # @param [Object] object
      # @param [Symbol] method_name
      def initialize(object, method_name, &process)
        @object = object
        @method_name = method_name
        @process = process
        @calls = Calls.new
      end

      # @attribute [r] object
      # @return [Object]
      attr_reader :object

      # @attribute [r] method_name
      # @return [Symbol]
      attr_reader :method_name

      # @attribute [r] calls
      # @return [Array<Peeek::Call>]
      attr_reader :calls

      #
      def link
        @original_method = enforce unless linked?
      end

      #
      def unlink
        if linked?
          revert(@original_method)
          remove_instance_variable(:@original_method)
        end
      end

      def linked?
        instance_variable_defined?(:@original_method)
      end

      def clear
        @calls.clear
      end

      def to_s
        method_prefix = self.class.instance_variable_get(:@method_prefix)
        method_expr = "#{@object}#{method_prefix}#{@method_name}"
        method_expr << ' (linked)' if linked?
        "#<#{self.class} #{method_expr}>"
      end

      protected

      def define_method(*args, &block)
        object = @object
        object = object.singleton_class unless Hook.module?(object)
        object.__send__(:define_method, @method_name, *args, &block)
      end

      def call(receiver, caller, args)
        call = Call.new(self, receiver, caller, args)

        if @process
          @process[call]
        else
          @calls << call
        end
      end

      %w(defined? enforce revert).each do |method_name|
        define_method(method_name) do
          raise ArgumentError
        end
      end
    end
  end
end
