require 'peeek/call'

def sample_backtrace
  ["koyomi.rb:7:in `print'", "koyomi.rb:21:in `<main>'"]
end

def sample_call(hook = nil)
  hook ||= stub('Peeek::Hook', :to_s => '#<Peeek::Hook String#% (linked)>')
  Peeek::Call.new(hook, sample_backtrace, '%s (%d)', ['Koyomi', 17])
end

describe Peeek::Call, '#hook' do
  it 'returns the value when constructed the call' do
    hook = :hook
    call = sample_call(hook)
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

describe Peeek::Call, '#to_s' do
  it 'returns the stringified call' do
    call = sample_call
    call.to_s.should == '#<Peeek::Hook String#% (linked)> from "%s (%d)" with ("Koyomi", 17) in koyomi.rb at 7'
  end
end
