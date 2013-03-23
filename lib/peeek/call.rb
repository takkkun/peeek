class Peeek
  class Call

    # Initialize the call.
    #
    # @param [Peeek::Hook] hook hook the call occurred
    # @param [Array<String>] backtrace backtrace the call occurred
    # @param [Module, Class, Object] receiver object that received the call
    # @param [Array] arguments arguments at the call
    def initialize(hook, backtrace, receiver, arguments)
      @hook = hook
      @backtrace = backtrace
      @file, @line = extract_file_and_line(backtrace.first)
      @receiver = receiver
      @arguments = arguments
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

    def to_s
      parts = [@hook.to_s]
      parts << "from #{@receiver.inspect}"

      if @arguments.size == 1
        parts << "with #{pretty(@arguments.first)}"
      elsif @arguments.size > 1
        parts << "with (#{@arguments.map(&method(:pretty)) * ', '})"
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

    def pretty(value)
      case value
      when Array
        elements = value.map(&method(:pretty))
        "[#{elements * ', '}]"
      when Hash
        elements = value.map { |key, value| "#{pretty(key)} => #{pretty(value)}" }
        "{#{elements * ', '}}"
      else
        value.inspect
      end
    end

  end
end
