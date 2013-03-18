class Peeek
  class Call

    def initialize(hook, receiver, caller, arguments)
      @hook = hook
      @receiver = receiver
      @caller = caller
      @arguments = arguments
    end

    def to_s
      file, line_number = @caller.first.split(':')
      "#{@hook.to_s} with #{pretty_arguments} from #{@receiver.inspect} in #{file} at #{line_number}"
    end

    private

    def pretty_arguments
      a(@arguments).gsub(/^\[|\]$/, '')
    end

    def a(value)
      case value
      when String, Symbol, Numeric
        value.inspect
      when Array
        elements = value.map(&method(:a))
        "[#{elements * ', '}]"
      when Hash
        elements = value.map { |key, value| "#{a(key)} => #{a(value)}" }
        "{#{elements * ', '}}"
      else
        value.to_s
      end
    end
  end
end
