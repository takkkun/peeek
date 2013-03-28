require 'peeek/hook/verdict'

describe Peeek::Hook::Verdict, '#any_module?' do
  before do
    m = described_class
    @object = Class.new { include m }.new
  end

  it 'is true if any module given' do
    @object.should be_any_module(Enumerable)
  end

  it 'is true if any class given' do
    @object.should be_any_module(String)
  end

  it 'is false if an instance given' do
    @object.should_not be_any_module('Koyomi')
  end
end

describe Peeek::Hook::Verdict, '#any_instance?' do
  before do
    m = described_class
    @object = Class.new { include m }.new
  end

  it 'is true if an instance given' do
    @object.should be_any_instance('Koyomi')
  end

  it 'is false if any module given' do
    @object.should_not be_any_instance(Enumerable)
  end

  it 'is false if any class given' do
    @object.should_not be_any_instance(String)
  end
end
