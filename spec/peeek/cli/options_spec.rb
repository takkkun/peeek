require 'peeek/cli/options'

describe Peeek::CLI::Options do
  let(:default_options) { described_class.new }

  describe 'deafult options' do
    subject { default_options }

    context 'encoding options', :if => described_class.encoding_options_enabled? do
      its(:external_encoding) { should == Encoding.default_external }
      its(:internal_encoding) { should == Encoding.default_internal }
    end

    its(:debug)               { should be_false }
    its(:verbose)             { should be_false }
    its(:working_directory)   { should be_nil }
    its(:directories_to_load) { should == [] }
    its(:required_libraries)  { should == [] }
    its(:hook_targets)        { should == [] }
    its(:command)             { should == '' }
    its(:arguments)           { should == [] }
  end

  subject { described_class.new(argv) }

  describe '-C option' do
    let(:argv) { %w(-C directory) }

    its(:working_directory) { should == 'directory' }
  end

  shared_examples_for 'accepting debug option' do
    let(:argv) { [option] }

    its(:debug) { should be_true }
  end

  describe '-d option' do
    it_behaves_like 'accepting debug option' do
      let(:option) { '-d' }
    end
  end

  describe '--debug option' do
    it_behaves_like 'accepting debug option' do
      let(:option) { '--debug' }
    end
  end

  describe '-e option' do
    let(:option) { '-e' }

    context 'when a command is specified' do
      let(:argv) { [option, 'puts "%s (%d)" % ["Koyomi", 18]'] }

      it { should be_command_given }
      its(:command) { should == 'puts "%s (%d)" % ["Koyomi", 18]' }
    end

    context 'when multiple commands are specified' do
      let(:argv) { [option, 'format = "%s (%d)"', option, 'puts format % ["Koyomi", 18]'] }

      it { should be_command_given }
      its(:command) { should == 'format = "%s (%d)"; puts format % ["Koyomi", 18]' }
    end

    context 'when commands is omitted' do
      let(:argv) { [option] }

      it do
        lambda { subject }.should raise_error(OptionParser::MissingArgument)
      end
    end
  end

  shared_examples_for 'accepting encoding option' do
    let(:utf_8)    { Encoding::UTF_8    }
    let(:us_ascii) { Encoding::US_ASCII }

    context 'when both external encoding and internal encoding are specifid' do
      let(:argv) { [option, 'utf-8:us-ascii'] }

      its(:external_encoding) { should == utf_8 }
      its(:internal_encoding) { should == us_ascii }
    end

    context 'when external encoding only is specified' do
      let(:argv) { [option, 'utf-8'] }

      its(:external_encoding) { should == utf_8 }
      its(:internal_encoding) { should == default_options.internal_encoding }
    end

    context 'when internal encoding only is specified' do
      let(:argv) { [option, ':us-ascii'] }

      its(:external_encoding) { should == default_options.external_encoding }
      its(:internal_encoding) { should == us_ascii }
    end

    context 'when external encoding is unknown encoding name' do
      let(:argv) { [option, 'undefined-encoding'] }

      it do
        lambda { subject }.should raise_error(ArgumentError, 'unknown encoding name - undefined-encoding')
      end
    end

    context 'when internal encoding is unknown encoding name' do
      let(:argv) { [option, ':undefined-encoding'] }

      it do
        lambda { subject }.should raise_error(ArgumentError, 'unknown encoding name - undefined-encoding')
      end
    end

    context 'when encodings is omitted' do
      let(:argv) { [option] }

      it do
        lambda { subject }.should raise_error(OptionParser::MissingArgument)
      end
    end
  end

  describe '-E option', :if => described_class.encoding_options_enabled? do
    it_behaves_like 'accepting encoding option' do
      let(:option) { '-E' }
    end
  end

  describe '--encoding option', :if => described_class.encoding_options_enabled? do
    it_behaves_like 'accepting encoding option' do
      let(:option) { '--encoding' }
    end
  end

  describe '-H option' do
    let(:option) { '-H' }

    context 'when a hook specifier is specified' do
      let(:argv) { [option, 'String#%'] }

      its(:hook_targets) {
        should == [Peeek::Hook::Specifier.new('String', '#', :%)]
      }
    end

    context 'when multiple hook specifiers is specified' do
      let(:argv) { [option, 'String#%', option, 'String#index'] }

      its(:hook_targets) {
        should == [
          Peeek::Hook::Specifier.new('String', '#', :%),
          Peeek::Hook::Specifier.new('String', '#', :index)
        ]
      }
    end

    context 'when hook specifiers is duplicated' do
      let(:argv) { [option, 'String#%', option, 'String#%'] }

      its(:hook_targets) {
        should == [Peeek::Hook::Specifier.new('String', '#', :%)]
      }
    end

    context 'when hook specifiers is omitted' do
      let(:argv) { [option] }

      it do
        lambda { subject }.should raise_error(OptionParser::MissingArgument)
      end
    end
  end

  shared_examples_for 'accepting multiple values' do |attr|
    context 'when a value is specified' do
      let(:argv) { [option, 'value'] }

      its(attr) { should == %w(value) }
    end

    context 'when multiple values is specified' do
      let(:argv) { [option, 'value1', option, 'value2'] }

      its(attr) { should == %w(value1 value2) }
    end

    context 'when values is duplicated' do
      let(:argv) { [option, 'value', option, 'value'] }

      its(attr) { should == %w(value) }
    end

    context 'when value is omitted' do
      let(:argv) { [option] }

      it do
        lambda { subject }.should raise_error(OptionParser::MissingArgument)
      end
    end
  end

  describe '-I option' do
    it_behaves_like 'accepting multiple values', :directories_to_load do
      let(:option) { '-I' }
    end
  end

  describe '-r option' do
    it_behaves_like 'accepting multiple values', :required_libraries do
      let(:option) { '-r' }
    end
  end

  shared_examples_for 'accepting version option' do
    let(:argv) { [option] }

    it { should be_version_requested }
  end

  describe '-v option' do
    let(:argv) { %w(-v) }

    it { should be_version_requested }
    its(:verbose) { should be_true }
  end

  shared_examples_for 'accepting verbose option' do
    let(:argv) { [option] }

    its(:verbose) { should be_true }
  end

  describe '-w option' do
    it_behaves_like 'accepting verbose option' do
      let(:option) { '-w' }
    end
  end

  describe '--verbose option' do
    it_behaves_like 'accepting verbose option' do
      let(:option) { '--verbose' }
    end
  end

  describe '-W option' do
    let(:option) { '-W' }

    context 'when the leve is 0' do
      let(:argv) { ["#{option}0"] }

      its(:verbose) { should be_nil }
    end

    context 'when the level is 1' do
      let(:argv) { ["#{option}1"] }

      its(:verbose) { should be_false }
    end

    context 'when the leve is 2' do
      let(:argv) { ["#{option}2"] }

      its(:verbose) { should be_true }
    end

    context 'when the level is other' do
      let(:argv) { ["#{option}3"] }

      it do
        lambda { subject }.should raise_error(ArgumentError, 'invalid warning level - 3')
      end
    end

    context 'when a level is omitted' do
      let(:argv) { [option] }

      its(:verbose) { should be_true }
    end
  end

  describe '--version option' do
    let(:argv) { %w(--version) }

    it { should be_version_requested }
    it { should_not be_continued }
  end

  shared_examples_for 'accepting help option' do
    let(:argv) { [option] }

    it do
      lambda { subject }.should raise_error(Peeek::CLI::Help, /^Usage: peeek/)
    end
  end

  describe '-h option' do
    it_behaves_like 'accepting help option' do
      let(:option) { '-h' }
    end
  end

  describe '--help option' do
    it_behaves_like 'accepting help option' do
      let(:option) { '--help' }
    end
  end

  describe 'extra options' do
    context 'when extra options is specified' do
      let(:argv) { %w(-HString#% example.rb) }

      it { should be_arguments_given }
      its(:arguments) { should == %w(example.rb) }
    end

    context 'when extra options is omitted' do
      let(:argv) { ['-HString#%', %(-e'puts "%s (%d)" % ["Koyomi", 18]')] }

      it { should_not be_arguments_given }
      its(:arguments) { should be_empty }
    end
  end
end
