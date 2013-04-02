require 'spec_helper'
require 'peeek/calls'

def sample_calls
  Peeek::Calls.new([
    call_stub(:return_value, :file => 'koyomi.rb',  :line =>  5, :receiver => String),
    call_stub(:exception,    :file => 'koyomi.rb',  :line =>  7, :receiver => String),
    call_stub(:return_value, :file => 'koyomi.rb',  :line => 11, :receiver => Numeric),
    call_stub(:return_value, :file => 'karen.rb',   :line =>  4, :receiver => String),
    call_stub(:return_value, :file => 'karen.rb',   :line =>  7, :receiver => Numeric),
    call_stub(:return_value, :file => 'karen.rb',   :line => 12, :receiver => Numeric),
    call_stub(:return_value, :file => 'tsukihi.rb', :line =>  2, :receiver => Numeric),
    call_stub(:return_value, :file => 'tsukihi.rb', :line =>  3, :receiver => String),
    call_stub(:return_value, :file => 'tsukihi.rb', :line => 12, :receiver => String)
  ])
end

describe Peeek::Calls, '#in' do
  it "returns an instance of #{described_class}" do
    filtered_calls = sample_calls.in('koyomi.rb')
    filtered_calls.should be_a(described_class)
  end

  it 'returns calls that corresponds to the name of the file' do
    filtered_calls = sample_calls.in('koyomi.rb')
    filtered_calls.should have(3).items
  end

  it 'supports Regexp' do
    filtered_calls = sample_calls.in(/^k/)
    filtered_calls.should have(6).items
  end
end

describe Peeek::Calls, '#at' do
  it "returns an instance of #{described_class}" do
    filtered_calls = sample_calls.at(7)
    filtered_calls.should be_a(described_class)
  end

  it 'returns calls that corresponds to the line number' do
    filtered_calls = sample_calls.at(7)
    filtered_calls.should have(2).items
  end

  it 'supports Range' do
    filtered_calls = sample_calls.at(1..10)
    filtered_calls.should have(6).items
  end
end

describe Peeek::Calls, '#from' do
  it "returns an instance of #{described_class}" do
    filtered_calls = sample_calls.from(String)
    filtered_calls.should be_a(described_class)
  end

  it 'returns calls that corresponds to the receiver' do
    filtered_calls = sample_calls.from(String)
    filtered_calls.should have(5).items
  end
end

describe Peeek::Calls, '#return_values' do
  it "returns an instance of #{described_class}" do
    filtered_calls = sample_calls.return_values
    filtered_calls.should be_a(described_class)
  end

  it 'returns calls that a value returned' do
    filtered_calls = sample_calls.return_values
    filtered_calls.should have(8).items
  end
end

describe Peeek::Calls, '#exceptions' do
  it "returns an instance of #{described_class}" do
    filtered_calls = sample_calls.exceptions
    filtered_calls.should be_a(described_class)
  end

  it 'returns calls that an exception raised' do
    filtered_calls = sample_calls.exceptions
    filtered_calls.should have(1).items
  end
end
