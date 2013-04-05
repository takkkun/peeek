require 'peeek/cli/options'
require 'peeek'

class Peeek
  class CLI

    # Initialize the CLI object.
    #
    # @param [Array<String>] argv arguments that is given from command line
    def initialize(argv)
      @options = Options.parse(argv)
    end

    # @attribute [r] options
    # @return [Peeek::CLI::Options] options to run from CLI
    attr_reader :options

    # Determine if
    #
    # @return whether
    def runnable?
      @options.version_requested? or @options.command_given? or @options.arguments_given?
    end

    # Run the command or the program file with a binding. And capture calls
    # that raised when running it.
    #
    # @param [Binding] binding context that runs the command or the program
    #   file
    # @return [Peeek::Calls] captured calls
    def run(binding)
      raise '' unless runnable?

      Encoding.default_external = @options.external_encoding
      Encoding.default_internal = @options.internal_encoding

      $DEBUG   = @options.debug
      $VERBOSE = @options.verbose

      Dir.chdir(@options.working_directory) if @options.working_directory
      $LOAD_PATH.unshift(*@options.directories_to_load)
      @options.required_libraries.each(&method(:require))

      hook_targets = @options.hook_targets.materialize(binding)
      process = setup_to_execute(binding)

      begin
        puts "peeek-#{VERSION}" if @options.version_requested?
        Peeek.capture(hook_targets, &process)
      rescue => e
        backtrace = e.backtrace.take_while { |line| line !~ %r{lib/peeek/cli\.rb} }
        e.set_backtrace(backtrace)
        raise e
      end
    end

    private

    def setup_to_execute(binding)
      if @options.command_given?
        set_argv(@options.arguments.dup)
        lambda { binding.eval(@options.command, '-e', 1) }
      elsif @options.arguments_given?
        path, *argv = @options.arguments
        set_argv(argv)
        lambda { load path }
      else
        set_argv(@options.arguments.dup)
        lambda { }
      end
    end

    def set_argv(argv)
      ARGV[0, ARGV.length] = argv
    end

  end
end
