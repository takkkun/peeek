require 'peeek/call'

def sample_backtrace
  ["koyomi.rb:7:in `print'", "koyomi.rb:21:in `<main>'"]
end

def sample_call(attrs = {})
  hook   = attrs[:hook] || stub('Peeek::Hook', :to_s => 'String#%')
  args   = attrs[:args] || ['Koyomi', 17]
  result = attrs[:result] || Peeek::Call::ReturnValue.new('Koyomi (17)')
  Peeek::Call.new(hook, sample_backtrace, '%s (%d)', args, result)
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
    call.arguments.should == ['Koyomi', 17]
  end
end

describe Peeek::Call, '#result' do
  it 'returns the value when constructed the call' do
    result = Peeek::Call::ReturnValue.new(:value)
    call = sample_call(:result => result)
    call.result.should == result
  end
end

describe Peeek::Call, '#return_value' do
  it 'returns value of the result' do
    call = sample_call(:result => Peeek::Call::ReturnValue.new(:value))
    call.return_value.should == :value
  end

  it 'raises TypeError if the call is raised an exception' do
    call = sample_call(:result => Peeek::Call::Exception.new(:value))
    lambda { call.return_value }.should raise_error(TypeError, "the call didn't return a value")
  end
end

describe Peeek::Call, '#exception' do
  it 'returns value of the result' do
    call = sample_call(:result => Peeek::Call::Exception.new(:value))
    call.exception.should == :value
  end

  it 'raises TypeError if the call returned a value' do
    call = sample_call(:result => Peeek::Call::ReturnValue.new(:value))
    lambda { call.exception }.should raise_error(TypeError, "the call didn't raised an exception")
  end
end

describe Peeek::Call, '#returned?' do
  it 'is true if the call returned a value' do
    call = sample_call(:result => Peeek::Call::ReturnValue.new(:value))
    call.should be_returned
  end

  it 'is false if the call is raised an exception' do
    call = sample_call(:result => Peeek::Call::Exception.new(:value))
    call.should_not be_returned
  end
end

describe Peeek::Call, '#raised?' do
  it 'is true if the call is raised an exception' do
    call = sample_call(:result => Peeek::Call::Exception.new(:value))
    call.should be_raised
  end

  it 'is false if the call returned a value' do
    call = sample_call(:result => Peeek::Call::ReturnValue.new(:value))
    call.should_not be_raised
  end
end

describe Peeek::Call, '#to_s' do
  context 'with no arguments' do
    it 'returns the stringified call' do
      call = sample_call(:args => [])
      call.to_s.should == 'String#% from "%s (%d)" returned "Koyomi (17)" in koyomi.rb at 7'
    end
  end

  context 'with an argument' do
    it 'returns the stringified call' do
      call = sample_call(:args => [:arg])
      call.to_s.should == 'String#% from "%s (%d)" with :arg returned "Koyomi (17)" in koyomi.rb at 7'
    end
  end

  context 'with multiple arguments' do
    it 'returns the stringified call' do
      call = sample_call(:args => [:arg1, :arg2])
      call.to_s.should == 'String#% from "%s (%d)" with (:arg1, :arg2) returned "Koyomi (17)" in koyomi.rb at 7'
    end
  end

  context 'with a return value result' do
    it 'returns the stringified call' do
      call = sample_call(:result => Peeek::Call::ReturnValue.new(:return_value))
      call.to_s.should == 'String#% from "%s (%d)" with ("Koyomi", 17) returned :return_value in koyomi.rb at 7'
    end
  end

  context 'with an exception result' do
    it 'returns the stringified call' do
      call = sample_call(:result => Peeek::Call::Exception.new(:exception))
      call.to_s.should == 'String#% from "%s (%d)" with ("Koyomi", 17) raised :exception in koyomi.rb at 7'
    end
  end
end
