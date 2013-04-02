require 'spec_helper'
require 'peeek/hook'

def sample_instance_hook(linker = nil)
  Peeek::Hook.create(String, :%).tap do |hook|
    hook.instance_variable_set(:@linker, linker) if linker
    hook.instance_variable_set(:@calls, Array.new(5))
  end
end

def sample_singleton_hook(linker = nil)
  Peeek::Hook.create($stdout, :write).tap do |hook|
    hook.instance_variable_set(:@linker, linker) if linker
    hook.instance_variable_set(:@calls, Array.new(4))
  end
end

describe Peeek::Hook, '.create' do
  it "returns an instance of #{described_class}" do
    hook = sample_instance_hook
    hook.should be_a(described_class)
  end

  it "returns a hook that corresponds to the object and the method name" do
    hook = sample_instance_hook
    hook.object.should == String
    hook.method_name.should == :%
  end

  context 'when specify implicitly' do
    it 'returns a hook to instance method if given any module or any class' do
      hook = described_class.create(String, :%)
      hook.object.should == String
      hook.method_name.should == :%
      hook.should be_instance
    end

    it 'returns a hook to singleton method if given any instance' do
      hook = described_class.create($stdout, :write)
      hook.object.should == $stdout
      hook.method_name.should == :write
      hook.should be_singleton
    end
  end

  context 'when specify instance method expressly' do
    it 'returns a hook to instance method if given any module or any class' do
      hook = described_class.create(String, '#%')
      hook.object.should == String
      hook.method_name.should == :%
      hook.should be_instance
    end

    it 'raises ArgumentError if given any instance' do
      lambda { described_class.create($stdout, '#write') }.should raise_error(ArgumentError, "can't create a hook of instance method to an instance of any class")
    end
  end

  context 'when specify singleton method expressly' do
    it 'returns a hook to singleton method if given any module or any class' do
      hook = described_class.create(String, '.new')
      hook.object.should == String
      hook.method_name.should == :new
      hook.should be_singleton
    end

    it 'returns a hook to singleton method if given any instance' do
      hook = described_class.create($stdout, '.write')
      hook.object.should == $stdout
      hook.method_name.should == :write
      hook.should be_singleton
    end
  end
end

describe Peeek::Hook, '.any_module?' do
  it 'is true if any module given' do
    described_class.should be_any_module(Enumerable)
  end

  it 'is true if any class given' do
    described_class.should be_any_module(String)
  end

  it 'is false if an instance given' do
    described_class.should_not be_any_module('Koyomi')
  end
end

describe Peeek::Hook, '.any_instance?' do
  it 'is true if an instance given' do
    described_class.should be_any_instance('Koyomi')
  end

  it 'is false if any module given' do
    described_class.should_not be_any_instance(Enumerable)
  end

  it 'is false if any class given' do
    described_class.should_not be_any_instance(String)
  end
end

describe Peeek::Hook, '#initialize' do
  it 'raises ArgumentError if the linker class is invalid' do
    lambda { described_class.new(String, :%, String) }.should raise_error(ArgumentError, 'invalid as linker class, Peeek::Hook::Instance or Peeek::Hook::Singleton are valid')
  end
end

describe Peeek::Hook, '#object' do
  it 'returns the value when constructed the hook' do
    hook = described_class.new(String, :%, Peeek::Hook::Instance)
    hook.object.should == String
  end
end

describe Peeek::Hook, '#method_name' do
  it 'returns the value when constructed the hook' do
    hook = described_class.new(String, :%, Peeek::Hook::Instance)
    hook.method_name.should == :%
  end
end

describe Peeek::Hook, '#instance?' do
  it 'is true if the hook is for instance method' do
    hook = sample_instance_hook
    hook.should be_instance
  end

  it 'is false if the hook is for singleton method' do
    hook = sample_singleton_hook
    hook.should_not be_instance
  end
end

describe Peeek::Hook, '#singleton?' do
  it 'is true if the hook is for singleton method' do
    hook = sample_singleton_hook
    hook.should be_singleton
  end

  it 'is false if the hook is for instance method' do
    hook = sample_instance_hook
    hook.should_not be_singleton
  end
end

describe Peeek::Hook, '#defined?' do
  before do
    @linker, original_method = instance_linker_stub(String, :%)
    @hook = sample_instance_hook(@linker)
  end

  it "calls #{described_class}::Linker#defined?" do
    @linker.should_receive(:defined?)
    @hook.defined?
  end

  it "returns return value from #{described_class}::Linker#defined?" do
    @linker.stub!(:defined? => true)
    return_value = @hook.defined?
    return_value.should == true
  end
end

describe Peeek::Hook, '#link' do
  before do
    @linker, @original_method = instance_linker_stub(String, :%)
    @hook = sample_instance_hook(@linker)
  end

  after do
    @hook.unlink
  end

  it "calls #{described_class}::Linker#link with the block" do
    @linker.should_receive(:link).with { }.and_return do |&block|
      block.arity.should == 3
      @original_method
    end

    @hook.link
  end

  it 'links the hook to the method' do
    @hook.should_not be_linked # assert
    @hook.link
    @hook.should be_linked
  end

  it 'returns self' do
    @hook.link.should equal(@hook)
  end

  context 'in linked' do
    before do
      @linker, original_method = instance_linker_stub(String, :%)
      @hook = sample_instance_hook(@linker)
      @hook.link
    end

    after do
      @hook.unlink
    end

    it "doesn't call #{described_class}::Linker#link" do
      @linker.should_not_receive(:link)
      @hook.link
    end

    it 'returns self' do
      @hook.link.should equal(@hook)
    end
  end
end

describe Peeek::Hook, '#unlink' do
  before do
    @linker, @original_method = instance_linker_stub(String, :%)
    @hook = sample_instance_hook(@linker)
    @hook.link
  end

  it "calls #{described_class}::Linker#unlink with the original method" do
    @linker.should_receive(:unlink).with(@original_method)
    @hook.unlink
  end

  it 'unlinks the hook from the method' do
    @hook.should be_linked # assert
    @hook.unlink
    @hook.should_not be_linked
  end

  it 'returns self' do
    @hook.unlink.should equal(@hook)
  end

  context 'in not linked' do
    before do
      @linker, original_method = instance_linker_stub(String, :%)
      @hook = sample_instance_hook(@linker)
    end

    it "doesn't call #{described_class}::Linker#unlink" do
      @linker.should_not_receive(:unlink)
      @hook.unlink
    end

    it 'returns self' do
      @hook.unlink.should equal(@hook)
    end
  end
end

describe Peeek::Hook, '#to_s' do
  context 'for instance method' do
    it 'returns the stringified hook' do
      hook = sample_instance_hook
      hook.to_s.should == 'String#%'
    end
  end

  context 'for singleton method' do
    it 'returns the stringified hook' do
      hook = sample_singleton_hook
      hook.to_s.should == "#{$stdout.inspect}.write"
    end
  end
end

describe Peeek::Hook, '#inspect' do
  context 'for instance method' do
    it 'inspects the hook' do
      hook = sample_instance_hook
      hook.inspect.should == "#<#{described_class} String#%>"
    end
  end

  context 'for singleton method' do
    it 'inspects the hook' do
      hook = sample_singleton_hook
      hook.inspect.should == "#<#{described_class} #{$stdout.inspect}.write>"
    end
  end

  context 'in linked' do
    before do
      @hook = sample_instance_hook
      @hook.link
    end

    after do
      @hook.unlink
    end

    it 'inspects the hook' do
      @hook.inspect.should == "#<#{described_class} String#% (linked)>"
    end
  end
end

describe 'recording of a call by', Peeek::Hook do
  before do
    @hook = Peeek::Hook.create(String, :%)
    @hook.link
  end

  after do
    @hook.unlink
  end

  it 'sets attributes to the call' do
    line = __LINE__; '%s (%d)' % ['Koyomi', 18]
    call = @hook.calls.first
    call.file.should == __FILE__
    call.line.should == line
    call.receiver.should == '%s (%d)'
    call.arguments.should == [['Koyomi', 18]]
  end

  context 'if a value returned' do
    it 'sets the return value to the call' do
      '%s (%d)' % ['Koyomi', 18]
      call = @hook.calls.first
      call.should be_returned
      call.return_value.should == 'Koyomi (18)'
    end

    it 'returns same value when called the method' do
      return_value = '%s (%d)' % ['Koyomi', 18]
      call = @hook.calls.first
      return_value.should equal(call.return_value)
    end
  end

  context 'if an exception raised' do
    it 'sets the exception to the call' do
      '%s (%d)' % ['Koyomi'] rescue
      call = @hook.calls.first
      call.should be_raised
      call.exception.should be_an(ArgumentError)
      call.exception.message.should == 'too few arguments'
    end

    it 'raises same exception when called the method' do
      exception = '%s (%d)' % ['Koyomi'] rescue $!
      call = @hook.calls.first
      exception.should equal(call.exception)
    end

    it 'raises the exception with valid backtrace' do
      line = __LINE__; exception = '%s (%d)' % ['Koyomi'] rescue $!
      exception.backtrace.first.should be_start_with("#{__FILE__}:#{line}")
    end
  end

  context 'with a block' do
    before do
      @hook.unlink
    end

    it 'calls the block with the call' do
      line = nil

      hook = Peeek::Hook.create(String, :%) do |call|
        call.file.should == __FILE__
        call.line.should == line
        call.receiver.should == '%s (%d)'
        call.arguments.should == [['Koyomi', 18]]
        call.should be_returned
        call.return_value.should == 'Koyomi (18)'
      end

      hook.link
      line = __LINE__; '%s (%d)' % ['Koyomi', 18]
      hook.unlink
    end
  end
end
