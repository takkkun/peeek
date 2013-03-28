require 'peeek/hook'

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
