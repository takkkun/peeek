require 'spec_helper'
require 'peeek/calls'

def calls
  [
   call_stub(:file => 'koyomi.rb',  :line =>  5, :receiver => String),
   call_stub(:file => 'koyomi.rb',  :line =>  7, :receiver => String),
   call_stub(:file => 'koyomi.rb',  :line => 11, :receiver => Numeric),
   call_stub(:file => 'karen.rb',   :line =>  4, :receiver => String),
   call_stub(:file => 'karen.rb',   :line =>  7, :receiver => Numeric),
   call_stub(:file => 'karen.rb',   :line => 12, :receiver => Numeric),
   call_stub(:file => 'tsukihi.rb', :line =>  2, :receiver => Numeric),
   call_stub(:file => 'tsukihi.rb', :line =>  3, :receiver => String),
   call_stub(:file => 'tsukihi.rb', :line => 12, :receiver => String)
  ]
end

describe Peeek::Calls, '#in' do
  before do
    @calls = described_class.new(calls)
  end

  it "returns an instance of #{described_class}" do
    filtered_calls = @calls.in('koyomi.rb')
    filtered_calls.should be_a(described_class)
  end

  it 'returns calls that corresponds to the name of the file' do
    filtered_calls = @calls.in('koyomi.rb')
    filtered_calls.should have(3).items
  end

  it 'supports Regexp' do
    filtered_calls = @calls.in(/^k/)
    filtered_calls.should have(6).items
  end
end

describe Peeek::Calls, '#at' do
  before do
    @calls = described_class.new(calls)
  end

  it "returns an instance of #{described_class}" do
    filtered_calls = @calls.at(7)
    filtered_calls.should be_a(described_class)
  end

  it 'returns calls that corresponds to the line number' do
    filtered_calls = @calls.at(7)
    filtered_calls.should have(2).items
  end

  it 'supports Range' do
    filtered_calls = @calls.at(1..10)
    filtered_calls.should have(6).items
  end
end

describe Peeek::Calls, '#from' do
  before do
    @calls = described_class.new(calls)
  end

  it "returns an instance of #{described_class}" do
    filtered_calls = @calls.from(String)
    filtered_calls.should be_a(described_class)
  end

  it 'returns calls that corresponds to the receiver' do
    filtered_calls = @calls.from(String)
    filtered_calls.should have(5).items
  end
end
