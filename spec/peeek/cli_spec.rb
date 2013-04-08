require 'peeek/cli'
require 'stringio'
require 'pathname'

describe Peeek::CLI do
  let(:test_input)  { StringIO.new }
  let(:test_output) { StringIO.new }

  describe '#initialize' do
    it "calls #{described_class}::Options.new with the argv" do
      Peeek::CLI::Options.should_receive(:new).with(['-v'])
      described_class.new(test_input, test_output, ['-v'])
    end

    context 'when need help' do
      it 'writes the help message to the output IO' do
        begin
          described_class.new(test_input, test_output, ['-h'])
        rescue SystemExit
        end

        test_output.string.should =~ /^Usage: peeek/
      end

      it 'raises SystemExit' do
        raised = begin
                   described_class.new(test_input, test_output, ['-h'])
                   false
                 rescue SystemExit
                   true
                 end

        raised.should be_true
      end
    end
  end

  describe '#options' do
    before { Peeek::CLI::Options.stub!(:new => 'options') }

    subject { described_class.new(test_input, test_output, ['-v']).options }

    it 'returns the options that was set when construct' do
      should == 'options'
    end
  end

  describe '#run' do
    def cli(command = nil)
      argv = command ? ['-e', command] : []
      cli = Peeek::CLI.new(test_input, test_output, argv)
      yield cli.options if block_given?
      cli
    end

    def local(expr)
      value = eval(expr)
      yield
      eval("#{expr} = value")
    end

    it 'sets options.external_encoding to Encoding.default_external' do
      cli = cli('print Encoding.default_external') do |options|
        options.external_encoding = 'utf-8'
      end

      local 'Encoding.default_external' do
        cli.run(binding)
        test_output.string.should == 'UTF-8'
      end
    end

    it 'sets options.internal_encoding to Encoding.default_internal' do
      cli = cli('print Encoding.default_internal') do |options|
        options.internal_encoding = 'us-ascii'
      end

      local 'Encoding.default_internal' do
        cli.run(binding)
        test_output.string.should == 'US-ASCII'
      end
    end

    it 'sets false to $DEBUG if options.debug is false' do
      cli = cli('print $DEBUG.inspect') do |options|
        options.debug = false
      end

      local '$DEBUG' do
        cli.run(binding)
        test_output.string.should == 'false'
      end
    end

    it 'sets true to $DEBUG if options.debug is true' do
      cli = cli('print $DEBUG.inspect') do |options|
        options.debug = true
      end

      local '$DEBUG' do
        cli.run(binding)
        test_output.string.should == 'true'
      end
    end

    it 'sets nil to $VERBOSE if options.verbose is nil' do
      cli = cli('print $VERBOSE.inspect') do |options|
        options.verbose = nil
      end

      local '$VERBOSE' do
        cli.run(binding)
        test_output.string.should == 'nil'
      end
    end

    it 'sets false to $VERBOSE if options.verbose is false' do
      cli = cli('print $VERBOSE.inspect') do |options|
        options.verbose = false
      end

      local '$VERBOSE' do
        cli.run(binding)
        test_output.string.should == 'false'
      end
    end

    it 'sets true to $VERBOSE if options.verbose is true' do
      cli = cli('print $VERBOSE.inspect') do |options|
        options.verbose = true
      end

      local '$VERBOSE' do
        cli.run(binding)
        test_output.string.should == 'true'
      end
    end

    it 'changes current directory to options.working_directory' do
      cli = cli('print Dir.pwd') do |options|
        options.working_directory = '..'
      end

      current_dir = Pathname(Dir.pwd)
      cli.run(binding)
      test_output.string.should == current_dir.parent.to_s
      Dir.chdir(current_dir.to_s)
    end

    it 'adds options.directories_to_load to head of $LOAD_PATH' do
      cli = cli('puts $LOAD_PATH') do |options|
        options.directories_to_load = %w(.. ../..)
      end

      output = StringIO.new
      output.puts('..')
      output.puts('../..')
      output.puts($LOAD_PATH)

      cli.run(binding)
      test_output.string.should == output.string
      2.times { $LOAD_PATH.shift }
    end

    it 'loads options.required_libraries' do
      cli = cli('print defined? Net::HTTP') do |options|
        options.required_libraries = %w(net/http)
      end

      defined?(Net::HTTP).should be_nil # assert
      cli.run(binding)
      test_output.string.should_not be_nil
    end

    it 'prints version' do
      cli = cli('puts "peeek"') do |options|
        options.stub!(:version_requested? => true)
      end

      output = StringIO.new
      output.puts("peeek-#{Peeek::VERSION}")
      output.puts('peeek')

      cli.run(binding)
      test_output.string.should == output.string
    end

    it 'hooks options.hook_targets' do
      cli = cli('print Peeek.current.hooks.inspect') do |options|
        options.hook_targets = [Peeek::Hook::Specifier.new('String', '#', :%)]
      end

      cli.run(binding)
      test_output.string.should == '[#<Peeek::Hook String#% (linked)>]'
    end

    it 'sets options.arguments to ARGV' do
      cli = cli('puts ARGV') do |options|
        options.arguments = %w(arg1 arg2)
      end

      output = StringIO.new
      output.puts('arg1')
      output.puts('arg2')

      cli.run(binding)
      test_output.string.should == output.string
    end

    it 'aborts process if options.continued? is false' do
      cli = cli('puts "peeek"') do |options|
        options.stub!(:version_requested? => true, :continued? => false)
      end

      output = StringIO.new
      output.puts("peeek-#{Peeek::VERSION}")

      cli.run(binding)
      test_output.string.should == output.string
    end

    it 'loads head of options.arguments as program file with tail of options.arguments' do
      cli = cli do |options|
        options.arguments = [File.join(File.dirname(__FILE__), 'cli_sample.rb'), *%w(arg1 arg2)]
      end

      output = StringIO.new
      output.puts('cli_sample.rb here')
      output.puts('arg1')
      output.puts('arg2')

      cli.run(binding)
      test_output.string.should == output.string
    end

    it 'evaluates content of input' do
      cli = cli()
      test_input.print('print "peeek"')
      test_input.rewind
      cli.run(binding)
      test_output.string.should == 'peeek'
    end

    it 'removes information about peeek gem from the backtrace of the raised exception' do
      cli = cli('fail')

      begin
        line = __LINE__; cli.run(binding)
      rescue => e
        e.backtrace[1].should =~ /#{__FILE__}:#{line}/
      end
    end
  end
end
