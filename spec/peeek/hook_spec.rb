require 'spec_helper'
require 'peeek/hook'

def sample_instance_hook(linker = nil)
  Peeek::Hook.create(String, :%).tap do |hook|
    hook.instance_variable_set(:@linker, linker) if linker
  end
end

def sample_singleton_hook
  Peeek::Hook.create($stdout, :write)
end

describe Peeek::Hook, '.create' do
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
end

describe Peeek::Hook, '#object' do
end

describe Peeek::Hook, '#method_name' do
end

describe Peeek::Hook, '#instance?' do
end

describe Peeek::Hook, '#singleton?' do
end

describe Peeek::Hook, '#defined?' do
end

describe Peeek::Hook, '#linked?' do
end

describe Peeek::Hook, '#link' do
  it 'returns self' do
    hook = sample_instance_hook
    hook.link.should be_equal(hook)
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
    @hook.unlink
    @hook.should_not be_linked
  end

  it 'returns self' do
    @hook.unlink.should be_equal(@hook)
  end

  context 'in not linked' do
    before do
      @linker, @original_method = instance_linker_stub(String, :%)
      @hook = sample_instance_hook(@linker)
    end

    it "doesn't call #{described_class}::Linker#unlink" do
      @linker.should_not_receive(:unlink)
      @hook.unlink
    end

    it 'returns self' do
      @hook.unlink.should be_equal(@hook)
    end
  end
end

describe Peeek::Hook, '#clear' do
  it 'returns self' do
    hook = sample_instance_hook
    hook.clear.should be_equal(hook)
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
      hook.to_s.should == '#<IO:<STDOUT>>.write'
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
      hook.inspect.should == "#<#{described_class} #<IO:<STDOUT>>.write>"
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
