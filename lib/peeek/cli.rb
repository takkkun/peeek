require 'peeek/cli/options'
require 'peeek'

class Peeek
  class CLI

    # Initialize the CLI object.
    #
    # @param [IO] input source to input
    # @param [IO] output destination to output the execution result
    # @param [Array<String>] argv arguments that is given from command line
    def initialize(input, output, argv)
      @input   = input
      @output  = output
      @options = Options.new(argv)
    rescue Help => e
      output.puts(e.message)
      exit
    end

    # @attribute [r] options
    # @return [Peeek::CLI::Options] options to run from CLI
    attr_reader :options

    # Run the command or the program file with a binding. And capture calls
    # that raised when running it.
    #
    # @param [Binding] binding context that runs the command or the program file
    # @return [Peeek::Calls] captured calls
    def run(binding)
      Encoding.default_external = @options.external_encoding
      Encoding.default_internal = @options.internal_encoding

      $DEBUG   = @options.debug
      $VERBOSE = @options.verbose

      Dir.chdir(@options.working_directory) if @options.working_directory
      $LOAD_PATH.unshift(*@options.directories_to_load)
      @options.required_libraries.each(&method(:require))

      hook_targets = materialize_hook_targets(binding)
      process = setup_to_execute(binding)

      @output.puts("peeek-#{VERSION}") if @options.version_requested?

      original_stdout = $stdout
      $stdout = @output

      begin
        Peeek.capture(hook_targets, &process)
      rescue => e
        e.set_backtrace(e.backtrace.reject { |line| line =~ %r{lib/peeek} })
        raise e
      ensure
        $stdout = original_stdout
      end
    end

    private

    def materialize_hook_targets(binding)
      hook_targets = @options.hook_targets.inject({}) do |hook_targets, hook_spec|
        hook_targets[hook_spec.object_name] ||= []
        hook_targets[hook_spec.object_name] << hook_spec.method_specifier
        hook_targets
      end

      hook_targets = hook_targets.map do |object_name, method_specs|
        type = binding.eval("defined? #{object_name}")
        raise "#{object_name} is undefined" if type.nil?
        raise "#{object_name} isn't a constant or a global variable" unless type == 'constant' || type == 'global-variable'
        [binding.eval(object_name), method_specs]
      end

      Hash[hook_targets]
    end

    def setup_to_execute(binding)
      if @options.command_given? and @options.continued?
        process_for { binding.eval(@options.command, '-e', 1) }
      elsif @options.arguments_given? and @options.continued?
        path, *argv = @options.arguments
        process_for(argv) { load path }
      elsif @options.version_requested?
        process_for { }
      else
        process_for { binding.eval(@input.read, '-', 1) }
      end
    end

    def process_for(argv = @options.arguments.dup, &process)
      ARGV[0, ARGV.length] = argv
      process
    end

  end
end
