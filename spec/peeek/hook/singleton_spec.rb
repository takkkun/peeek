require 'peeek/hook/singleton'

def sample_singleton_linker(method_name = :quote)
  Peeek::Hook::Singleton.new(Regexp, method_name)
end

describe Peeek::Hook::Singleton, '#method_prefix' do
  it 'returns "."' do
    linker = sample_singleton_linker
    linker.method_prefix.should == '.'
  end
end

describe Peeek::Hook::Singleton, '#defined?' do
  it 'is true if the method is defined in the object' do
    linker = sample_singleton_linker
    linker.should be_defined
  end

  it 'is false if the method is not defined in the object' do
    linker = sample_singleton_linker(:undefined_method)
    linker.should_not be_defined
  end
end

describe Peeek::Hook::Singleton, '#link' do
  before do
    @original_method = Regexp.method(:quote)
    @linker = sample_singleton_linker
  end

  after do
    @linker.unlink(@original_method)
  end

  it 'gives appropriate arguments to the block when calling the method' do
    block_args = nil
    @linker.link { |*args| block_args = args }
    Regexp.quote('.')
    block_args[0][0].should =~ %r(spec/peeek/hook/singleton_spec.rb)
    block_args[1].should == Regexp
    block_args[2].should == ['.']
  end

  it 'is return value from the block as return value from the method' do
    return_value = 'return_value'
    @linker.link { |*args| return_value }
    Regexp.quote('.').should be_equal(return_value)
  end

  it 'is exception from the block as exception from the method' do
    @linker.link { |*args| raise 'exception' }
    lambda { Regexp.quote('.') }.should raise_error('exception')
  end

  it 'returns the original method' do
    @linker.link { }.should == @original_method
  end

  it 'raises ArgumentError if a block not given' do
    lambda { @linker.link }.should raise_error(ArgumentError, 'block not supplied')
  end
end

describe Peeek::Hook::Singleton, '#unlink' do
  before do
    @original_method = Regexp.method(:quote)
    @linker = sample_singleton_linker
    @linker.link { fail }
  end

  it 'defines method with the original method' do
    call = lambda { Regexp.quote('.') }

    # assert
    call.should raise_error

    @linker.unlink(@original_method)
    call.should_not raise_error
    call[].should == '\.'
  end
end
