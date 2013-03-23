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

  end
end
