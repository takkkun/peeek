class Peeek
  class Calls < Array

    # Filter the calls by name of a file.
    #
    # @param [String, Regexp] file name or pattern of a file
    # @return [Peeek::Calls] filtered calls
    def in(file)
      Calls.new(select { |call| file === call.file })
    end

    # Filter the calls by line number.
    #
    # @param [Number, Range<Number>] line line number or range of lines
    # @return [Peeek::Calls] filtered calls
    def at(line)
      Calls.new(select { |call| line === call.line })
    end

    # Filter the calls by a receiver.
    #
    # @param [Module, Class, Object] receiver
    # @return [Peeek::Calls] filtered calls
    def from(receiver)
      Calls.new(select { |call| call.receiver == receiver })
    end

    # Filter only the calls that a value returned.
    #
    # @return [Peeek::Calls] filtered calls
    def return_values
      Calls.new(select(&:returned?))
    end

    # Filter only the calls that an exception raised.
    #
    # @return [Peeek::Calls] filtered calls
    def exceptions
      Calls.new(select(&:raised?))
    end

  end
end
