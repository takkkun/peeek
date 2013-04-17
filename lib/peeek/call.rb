class Peeek
  class Call

    # Initialize the call.
    #
    # @param [Peeek::Hook] hook hook the call occurred
    # @param [Array<String>] backtrace backtrace the call occurred
    # @param [Module, Class, Object] receiver object that received the call
    # @param [Array] arguments arguments at the call
    # @param [Proc] block block at the call
    # @param [Peeek::Call::Result] result result of the call
    def initialize(hook, backtrace, receiver, arguments, block, result)
      raise ArgumentError, 'invalid as result' unless result.is_a?(Result)
      @hook = hook
      @backtrace = backtrace
      @file, @line = extract_file_and_line(backtrace.first)
      @receiver = receiver
      @arguments = arguments
      @block = block
      @result = result
    end

    # @attribute [r] hook
    # @return [Peeek::Hook] hook the call occurred
    attr_reader :hook

    # @attribute [r] backtrace
    # @return [Array<String>] backtrace the call occurred
    attr_reader :backtrace

    # @attribute [r] file
    # @return [String] name of file the call occurred
    attr_reader :file

    # @attribute [r] line
    # @return [Integer] line number the call occurred
    attr_reader :line

    # @attribute [r] receiver
    # @return [Module, Class, Object] object that received the call
    attr_reader :receiver

    # @attribute [r] arguments
    # @return [Array] arguments at the call
    attr_reader :arguments

    # @attribute [r] block
    # @return [Proc] block at the call
    attr_reader :block

    # @attribute [r] result
    # @return [Peeek::Call::Result] result of the call
    attr_reader :result

    # @attribute [r] return_value
    # @return [Object] value that the call returned
    def return_value
      raise TypeError, "the call didn't return a value" unless returned?
      @result.value
    end

    # @attribute [r] exception
    # @return [StandardError] exception that raised from the call
    def exception
      raise TypeError, "the call didn't raised an exception" unless raised?
      @result.value
    end

    # Determine if the result is a return value.
    #
    # @return whether the result is a return value
    def returned?
      @result.is_a?(ReturnValue)
    end

    # Determine if the result is an exception.
    #
    # @return whether the result is an exception
    def raised?
      @result.is_a?(Exception)
    end

    def to_s
      parts = [@hook.to_s]
      parts << "from #{@receiver.inspect}"

      if @arguments.size == 1
        parts << "with #{@arguments.first.inspect}"
      elsif @arguments.size > 1
        parts << "with (#{@arguments.map(&:inspect) * ', '})"
      end

      if @block
        conjunction = @arguments.empty? ? 'with' : 'and'
        parts << "#{conjunction} a block"
      end

      if returned?
        parts << "returned #{return_value.inspect}"
      elsif raised?
        parts << "raised #{exception.inspect}"
      end

      parts << "in #{@file}"
      parts << "at #{@line}"
      parts * ' '
    end

    private

    def extract_file_and_line(string)
      _, file, line = /^(.+):(\d+)(?::in\s+|$)/.match(string).to_a
      raise ArgumentError, 'invalid as string of backtrace' unless file and line
      [file, line.to_i]
    end

    class Result

      # Initialize the result.
      #
      # @param [Object] value value of the result
      def initialize(value)
        @value = value
      end

      # @attribute [r] value
      # @return [Object] value of the result
      attr_reader :value

      def ==(other)
        self.class == other.class && @value == other.value
      end
      alias eql? ==

      def hash
        (self.class.hash << 32) + @value.hash
      end

    end

    class ReturnValue < Result; end
    class Exception < Result; end

  end
end
