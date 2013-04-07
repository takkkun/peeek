require 'peeek/hook/specifier'

describe Peeek::Hook::Specifier do
  let(:sample_hook_specifier) { described_class.parse('String#%') }

  it 'identifies as key in a hash' do
    hash = {sample_hook_specifier => :hook_spec}
    hash.should     be_key(described_class.parse('String#%'))
    hash.should_not be_key(described_class.parse('String#index'))
    hash.should_not be_key(described_class.parse('Regexp#%'))
    hash.should_not be_key(described_class.parse('String.%'))
  end

  describe '.parse' do
    context 'when given instance method name' do
      subject { described_class.parse('String#%') }

      it { should == described_class.new('String', '#', :%) }
    end

    context 'when given singleton method name' do
      subject { described_class.parse('Regexp.quote') }

      it { should == described_class.new('Regexp', '.', :quote) }
    end

    context 'when given singleton method name' do
      subject { described_class.parse('Regexp.#quote') }

      it { should == described_class.new('Regexp', '.', :quote) }
    end

    context 'when given singleton method name' do
      subject { described_class.parse('Regexp::quote') }

      it { should == described_class.new('Regexp', '.', :quote) }
    end

    context 'when given nested object name' do
      subject { described_class.parse('Net::HTTP#request') }

      it { should == described_class.new('Net::HTTP', '#', :request) }
    end

    context "when a method name isn't specified" do
      subject { described_class.parse('String') }

      it do
        expect { subject }.to raise_error(ArgumentError, %(method name that is target of hook isn't specified in "String"))
      end
    end

    context 'when an object name is empty' do
      subject { described_class.parse('#%') }

      it do
        expect { subject }.to raise_error(ArgumentError, %(object name should not be empty for "#%"))
      end
    end

    context 'when a method name is empty' do
      subject { described_class.parse('String#') }

      it do
        expect { subject }.to raise_error(ArgumentError, %(method name should not be empty for "String#"))
      end
    end
  end

  describe '#initialize' do
    context 'when invalid method prefix is specified' do
      subject { described_class.new('String', '!', :%) }

      it do
        expect { subject }.to raise_error(ArgumentError, 'invalid method prefix, "#", ".", ".#" or "::" are valid')
      end
    end
  end

  describe '#method_specifier' do
    subject { sample_hook_specifier.method_specifier }

    it { should == '#%' }
  end

  describe '#to_s' do
    subject { sample_hook_specifier.to_s }

    it { should == 'String#%' }
  end

  describe '#inspect' do
    subject { sample_hook_specifier.inspect }

    it { should == "#<#{described_class} String#%>" }
  end

  describe '#==' do
    subject { sample_hook_specifier }

    it { should     == described_class.parse('String#%') }
    it { should_not == described_class.parse('String#index') }
    it { should_not == described_class.parse('Regexp#%') }
    it { should_not == described_class.parse('String.%') }
    it { should_not == 'String#%' }
  end
end
