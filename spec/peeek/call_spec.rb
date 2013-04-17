require 'peeek/call'

def sample_call(attrs = {})
  hook   = attrs[:hook] || stub('Peeek::Hook', :to_s => 'String#%')
  args   = attrs[:args] || ['Koyomi', 18]
  block  = attrs.key?(:block) ? attrs[:block] : lambda { }
  result = attrs[:result] || Peeek::Call::ReturnValue.new('Koyomi (18)')
  Peeek::Call.new(hook, sample_backtrace, '%s (%d)', args, block, result)
end

def sample_backtrace
  ["koyomi.rb:7:in `print'", "koyomi.rb:21:in `<main>'"]
end

def sample_return_value
  Peeek::Call::ReturnValue.new(:return_value)
end

def sample_exception
  Peeek::Call::Exception.new(:exception)
end

describe Peeek::Call, '#initialize' do
  it 'raises ArgumentError if the result is invalid' do
    lambda { sample_call(:result => :result) }.should raise_error(ArgumentError, 'invalid as result')
  end
end

describe Peeek::Call, '#hook' do
  it 'returns the value when constructed the call' do
    hook = :hook
    call = sample_call(:hook => hook)
    call.hook.should == hook
  end
end

describe Peeek::Call, '#backtrace' do
  it 'returns the value when constructed the call' do
    call = sample_call
    call.backtrace.should == sample_backtrace
  end
end

describe Peeek::Call, '#file' do
  it 'returns name of top file on the backtrace' do
    call = sample_call
    call.file.should == 'koyomi.rb'
  end
end

describe Peeek::Call, '#line' do
  it 'returns top line number on the backtrace' do
    call = sample_call
    call.line.should == 7
  end
end

describe Peeek::Call, '#receiver' do
  it 'returns the value when constructed the call' do
    call = sample_call
    call.receiver.should == '%s (%d)'
  end
end

describe Peeek::Call, '#arguments' do
  it 'returns the value when constructed the call' do
    call = sample_call
    call.arguments.should == ['Koyomi', 18]
  end
end

describe Peeek::Call, '#block' do
  it 'returns the value when constructed the call' do
    block = lambda { }
    call = sample_call(:block => block)
    call.block.should == block
  end
end

describe Peeek::Call, '#result' do
  it 'returns the value when constructed the call' do
    result = sample_return_value
    call = sample_call(:result => result)
    call.result.should == result
  end
end

describe Peeek::Call, '#return_value' do
  it 'returns value of the result' do
    call = sample_call(:result => sample_return_value)
    call.return_value.should == :return_value
  end

  it 'raises TypeError if the call is raised an exception' do
    call = sample_call(:result => sample_exception)
    lambda { call.return_value }.should raise_error(TypeError, "the call didn't return a value")
  end
end

describe Peeek::Call, '#exception' do
  it 'returns value of the result' do
    call = sample_call(:result => sample_exception)
    call.exception.should == :exception
  end

  it 'raises TypeError if the call returned a value' do
    call = sample_call(:result => sample_return_value)
    lambda { call.exception }.should raise_error(TypeError, "the call didn't raised an exception")
  end
end

describe Peeek::Call, '#returned?' do
  it 'is true if the call returned a value' do
    call = sample_call(:result => sample_return_value)
    call.should be_returned
  end

  it 'is false if the call is raised an exception' do
    call = sample_call(:result => sample_exception)
    call.should_not be_returned
  end
end

describe Peeek::Call, '#raised?' do
  it 'is true if the call is raised an exception' do
    call = sample_call(:result => sample_exception)
    call.should be_raised
  end

  it 'is false if the call returned a value' do
    call = sample_call(:result => sample_return_value)
    call.should_not be_raised
  end
end

describe Peeek::Call, '#to_s' do
  context 'with no arguments' do
    it 'returns the stringified call' do
      call = sample_call(:args => [])
      call.to_s.should == 'String#% from "%s (%d)" with a block returned "Koyomi (18)" in koyomi.rb at 7'
    end
  end

  context 'with an argument' do
    it 'returns the stringified call' do
      call = sample_call(:args => [:arg])
      call.to_s.should == 'String#% from "%s (%d)" with :arg and a block returned "Koyomi (18)" in koyomi.rb at 7'
    end
  end

  context 'with multiple arguments' do
    it 'returns the stringified call' do
      call = sample_call(:args => [:arg1, :arg2])
      call.to_s.should == 'String#% from "%s (%d)" with (:arg1, :arg2) and a block returned "Koyomi (18)" in koyomi.rb at 7'
    end
  end

  context 'with no block' do
    it 'returns the stringified call' do
      call = sample_call(:block => nil)
      call.to_s.should == 'String#% from "%s (%d)" with ("Koyomi", 18) returned "Koyomi (18)" in koyomi.rb at 7'
    end
  end

  context 'with a block' do
    it 'returns the stringified call' do
      call = sample_call(:block => lambda { })
      call.to_s.should == 'String#% from "%s (%d)" with ("Koyomi", 18) and a block returned "Koyomi (18)" in koyomi.rb at 7'
    end
  end

  context 'with a return value result' do
    it 'returns the stringified call' do
      call = sample_call(:result => sample_return_value)
      call.to_s.should == 'String#% from "%s (%d)" with ("Koyomi", 18) and a block returned :return_value in koyomi.rb at 7'
    end
  end

  context 'with an exception result' do
    it 'returns the stringified call' do
      call = sample_call(:result => sample_exception)
      call.to_s.should == 'String#% from "%s (%d)" with ("Koyomi", 18) and a block raised :exception in koyomi.rb at 7'
    end
  end
end

describe Peeek::Call::ReturnValue do
  it 'inhertis Peeek::Call::Result' do
    result = described_class.allocate
    result.should be_a(Peeek::Call::Result)
  end

  it 'identifies as key in a hash' do
    hash = {sample_return_value => :return_value}
    hash.should     be_key(sample_return_value)
    hash.should_not be_key(sample_exception)
    hash.should_not be_key(described_class.new(:other_return_value))
    hash.should_not be_key(Peeek::Call::Exception.new(:return_value))
  end
end

describe Peeek::Call::ReturnValue, '#value' do
  it 'returns the value when constructed the result' do
    result = sample_return_value
    result.value.should == :return_value
  end
end

describe Peeek::Call::ReturnValue, '#==' do
  it 'verifies equivalency' do
    result = sample_return_value
    result.should     == sample_return_value
    result.should_not == sample_exception
    result.should_not == described_class.new(:other_return_value)
    result.should_not == Peeek::Call::Exception.new(:return_value)
  end
end

describe Peeek::Call::Exception do
  it 'inhertis Peeek::Call::Result' do
    result = described_class.allocate
    result.should be_a(Peeek::Call::Result)
  end

  it 'identifies as key in a hash' do
    hash = {sample_exception => :exception}
    hash.should     be_key(sample_exception)
    hash.should_not be_key(sample_return_value)
    hash.should_not be_key(described_class.new(:other_exception))
    hash.should_not be_key(Peeek::Call::ReturnValue.new(:exception))
  end
end

describe Peeek::Call::Exception, '#value' do
  it 'returns the value when constructed the result' do
    result = sample_exception
    result.value.should == :exception
  end
end

describe Peeek::Call::Exception, '#==' do
  it 'verifies equivalency' do
    result = sample_exception
    result.should     == sample_exception
    result.should_not == sample_return_value
    result.should_not == described_class.new(:other_exception)
    result.should_not == Peeek::Call::ReturnValue.new(:exception)
  end
end
