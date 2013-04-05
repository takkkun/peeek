require 'optparse'
require 'stringio'
require 'peeek/cli/hook_specifiers'

class Peeek
  class CLI
    class Help < StandardError; end

    class Options

      SILENCE = 0
      MEDIUM  = 1
      VERBOSE = 2

      # @method parse(argv)
      #
      # Parse arguments that is given from command line.
      #
      # @param [Array<String>] argv arguments that is given from command line
      # @return [Peeek::CLI::Options] options to run from CLI
      instance_eval { alias parse new }

      # Initialize the CLI options.
      #
      # @param [Array<String>] argv arguments that is given from command line
      def initialize(argv = [])
        @debug             = $DEBUG
        @verbose           = $VERBOSE
        @version_requested = false

        opt = OptionParser.new
        opt.banner = 'Usage: peeek [switches] [--] [programfile] [arguments]'
        opt.summary_indent = ' ' * 2
        opt.summary_width = 15

        @working_directory = nil

        opt.on('-Cdirectory', 'cd to directory before executing your script') do |directory|
          @working_directory = directory
        end

        opt.on('-d', '--debug', 'set debugging flags (set $DEBUG to true)') do
          @debug = true
          @verbose = verbose_by(VERBOSE)
        end

        commands = []

        opt.on("-e 'command'", "one line of script. Several -e's allowed. Omit [programfile]") do |command|
          commands << command
        end

        @external_encoding = Encoding.default_external
        @internal_encoding = Encoding.default_internal

        opt.on('-Eex[:in]', '--encoding=ex[:in]', 'specify the default external and internal character encodings') do |encodings|
          external_encoding, internal_encoding = parse_encodings(encodings)
          @external_encoding = external_encoding if external_encoding
          @internal_encoding = internal_encoding
        end

        @hook_targets = HookSpecifiers.new

        opt.on('-Hspec', '--hook=spec', "method name that is target of hook") do |hook_spec|
          @hook_targets << hook_spec
        end

        @directories_to_load = []

        opt.on('-Idirectory', 'specify $LOAD_PATH directory (may be used more than once)') do |directory|
          @directories_to_load << directory
        end

        @required_libraries = []

        opt.on('-rlibrary', 'require the library before executing your script') do |library|
          @required_libraries << library
        end

        opt.on('-v', '--verbose', 'print version number, then turn on verbose mode') do
          @verbose = verbose_by(VERBOSE)
          @version_requested = true
        end

        opt.on('-w', 'turn warnings on for your script') do
          @verbose = verbose_by(VERBOSE)
        end

        level_strings = [:SILENCE, :MEDIUM, :VERBOSE].map do |const_name|
          "#{self.class.const_get(const_name)}=#{const_name.to_s.downcase}"
        end

        opt.on("-W[level=#{VERBOSE}]", "set warning level; #{level_strings * ', '}", Integer) do |level|
          @verbose = verbose_by(level || VERBOSE)
        end

        opt.on('--version', 'print the version') do
          @version_requested = true
        end

        opt.on_tail('-h', '--help', 'show this message') do
          raise create_help(opt)
        end

        @arguments = opt.order(argv)
        @command = commands * ';'
      end

      # @attribute external_encoding
      # @return [Encoding]
      attr_reader :external_encoding

      def external_encoding=(encoding)
        @external_encoding = Encoding.find(encoding)
      end

      # @attribute internal_encoding
      # @return [Encoding]
      attr_reader :internal_encoding

      def internal_encoding=(encoding)
        @internal_encoding = Encoding.find(encoding)
      end

      # @attribute debug
      # @return [Boolean]
      attr_accessor :debug

      # @attribute verbose
      # @return [Boolean, nil]
      attr_accessor :verbose

      # @attribute working_directory
      # @return [String]
      # @return [nil]
      attr_accessor :working_directory

      # @attribute directories_to_load
      # @return [Array<String>]
      attr_accessor :directories_to_load

      # @attribute required_libraries
      # @return [Array<String>]
      attr_accessor :required_libraries

      # @attribute [r] hook_specifiers
      # @return [Peeek::CLI::HookSpecifiers] targets to hook
      attr_reader :hook_targets

      # @attribute command
      # @return [String] Ruby code to execute
      attr_accessor :command

      # @attribute arguments
      # @return [Array<String>] arguments to a command or a program file
      attr_accessor :arguments

      # Determine if print of the version requested.
      #
      # @return whether print of the version requested
      def version_requested?
        @version_requested
      end

      # Determine if a command given.
      #
      # @return whether a command given
      def command_given?
        !@command.empty?
      end

      # Determine if arguments given.
      #
      # @return whether arguments given
      def arguments_given?
        !@arguments.empty?
      end

      private

      def parse_encodings(encodings)
        encodings = encodings.split(':')
        encodings.map { |encoding| encoding.empty? ? nil : Encoding.find(encoding) }
      end

      def verbose_by(level)
        verbose = {0 => nil, 1 => false, 2 => true}
        raise ArgumentError, "invalid warning level - #{level}" unless verbose.key?(level)
        verbose[level]
      end

      def create_help(opt)
        only_long_option_regexp = /^#{opt.summary_indent}(\s+)(--\S+)(\s*)(.*)$/

        message = StringIO.new
        message.puts(opt.banner)

        opt.summarize('', opt.summary_width, 80, opt.summary_indent) do |line|
          line.chomp!
          _, extra_spaces, long_option, summary_spaces, description = only_long_option_regexp.match(line).to_a
          line = opt.summary_indent + long_option + summary_spaces + extra_spaces + description if _
          message.puts(line)
        end

        Help.new(message.string)
      end

    end
  end
end
