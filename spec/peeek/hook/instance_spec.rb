require 'peeek/hook/instance'

def sample_instance_linker(method_name = :%)
  Peeek::Hook::Instance.new(String, method_name)
end

describe Peeek::Hook::Instance, '#method_prefix' do
  it 'returns "#"' do
    linker = sample_instance_linker
    linker.method_prefix.should == '#'
  end
end

describe Peeek::Hook::Instance, '#defined?' do
  it 'is true if the method is defined in the object' do
    linker = sample_instance_linker
    linker.should be_defined
  end

  it 'is false if the method is not defined in the object' do
    linker = sample_instance_linker(:undefined_method)
    linker.should_not be_defined
  end
end

describe Peeek::Hook::Instance, '#link' do
  before do
    @original_method = String.instance_method(:%)
    @linker = sample_instance_linker
  end

  after do
    @linker.unlink(@original_method)
  end

  it 'gives appropriate arguments to the block when calling the method' do
    block_args = nil
    @linker.link { |*args| block_args = args }
    '%s (%d)' % ['Koyomi', 17]
    block_args[0][0].should =~ %r(spec/peeek/hook/instance_spec.rb)
    block_args[1].should == '%s (%d)'
    block_args[2].should == [['Koyomi', 17]]
  end

  it 'is return value from the block as return value from the method' do
    return_value = 'return_value'
    @linker.link { |*args| return_value }
    ('%s (%d)' % ['Koyomi', 17]).should be_equal(return_value)
  end

  it 'is exception from the block as exception from the method' do
    @linker.link { |*args| raise 'exception' }
    lambda { '%s (%d)' % ['Koyomi', 17] }.should raise_error('exception')
  end

  it 'returns the original method' do
    @linker.link { }.should == @original_method
  end

  it 'raises ArgumentError if a block not given' do
    lambda { @linker.link }.should raise_error(ArgumentError, 'block not supplied')
  end
end

describe Peeek::Hook::Instance, '#unlink' do
  before do
    @original_method = String.instance_method(:%)
    @linker = sample_instance_linker
    @linker.link { fail }
  end

  it 'defines method with the original method' do
    call = lambda { '%s (%d)' % ['Koyomi', 17] }

    # assert
    call.should raise_error

    @linker.unlink(@original_method)
    call.should_not raise_error
    call[].should == 'Koyomi (17)'
  end
end
