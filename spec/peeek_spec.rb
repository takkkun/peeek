require 'spec_helper'
require 'peeek'

describe Peeek, '.global' do
  it 'returns the Peeek object' do
    described_class.global.should be_a(described_class)
  end

  it 'returns same object' do
    peeek = described_class.global
    described_class.global.should equal(peeek)
  end
end

describe Peeek, '.current' do
  it 'returns the Peeek object' do
    described_class.current.should be_a(described_class)
  end

  it 'returns same object' do
    peeek = described_class.current
    described_class.current.should equal(peeek)
  end
end

describe Peeek, '.local' do
  it 'returns return value from the block' do
    result = described_class.local { 'local' }
    result.should == 'local'
  end

  it 'switches the current Peeek object in the block' do
    peeek = described_class.current

    described_class.local do
      described_class.current.should_not equal(peeek)
    end
  end

  it 'gets back the current Peeek object after calling' do
    peeek = described_class.current
    described_class.local { }
    described_class.current.should equal(peeek)
  end

  it 'supports nested calling' do
    peeek1 = described_class.current

    described_class.local do
      peeek2 = described_class.current

      described_class.local do
        peeek3 = described_class.current
        described_class.local { }
        described_class.current.should equal(peeek3)
      end

      described_class.current.should equal(peeek2)
    end

    described_class.current.should equal(peeek1)
  end

  it 'unlinks the hooks of the current Peeek object over the block in the block, and revokes supervision' do
    described_class.local do
      peeek = described_class.current
      peeek.hook(String, :to_s, :undefined_method)
      peeek.hooks.get(String, :to_s).should be_linked # assert
      peeek.hooks.get(String, :undefined_method).should_not be_linked # assert
      String.should be_supervised_for_instance # assert

      described_class.local do
        peeek.hooks.should have(2).items
        peeek.hooks.get(String, :to_s).should_not be_linked
        peeek.hooks.get(String, :undefined_method).should_not be_linked
        String.should_not be_supervised_for_instance
      end
    end
  end

  it 'links the hooks of the current Peeek object over the block after calling, and starts supervision' do
    described_class.local do
      peeek = described_class.current
      peeek.hook(String, :to_s, :undefined_method)
      described_class.local { }
      peeek.hooks.should have(2).items
      peeek.hooks.get(String, :to_s).should be_linked
      peeek.hooks.get(String, :undefined_method).should_not be_linked
      String.should be_supervised_for_instance
    end
  end

  it 'releases the current Peeek object in the block after calling' do
    hook = described_class.local do
      described_class.current.hook(String, :%, :undefined_method)
      '%s (%d)' % ['Koyomi', 18]
      String.should be_supervised_for_instance # assert

      described_class.current.hooks.get(String, :%).tap do |hook|
        hook.should be_linked
        hook.calls.should have(1).items
      end
    end

    hook.should_not be_linked
    hook.calls.should be_empty
    String.should_not be_supervised_for_instance
  end

  it 'raises ArgumentError if a block not given' do
    lambda { described_class.local }.should raise_error(ArgumentError, 'block not supplied')
  end
end

describe Peeek, '.capture' do
  it "calls #{described_class}.local with a block" do
    described_class.should_receive(:local).with { }
    described_class.capture(String => :%) { }
  end

  it 'links hooks to the objects and the methods in the block' do
    described_class.capture(String => [:%, :index], $stdout => :write) do
      hooks = described_class.current.hooks
      hooks.get(String, :%).should be_linked
      hooks.get(String, :index).should be_linked
      hooks.get($stdout, :write).should be_linked
    end
  end

  it "returns an instance of #{described_class}::Calls" do
    calls = described_class.capture(String => :%) { }
    calls.should be_a(Peeek::Calls)
  end

  it 'returns result that captured calls in the block' do
    calls = described_class.capture(String => :%) do
      format = '%s (%d)'
      format % ['Koyomi',  18]
      format % ['Karen',   14]
      format % ['Tsukihi', 14]
    end

    calls.should have(3).items
  end

  it 'raises ArgumentError if a block not given' do
    lambda { described_class.capture(String => :%) }.should raise_error(ArgumentError, 'block not supplied')
  end
end

describe Peeek, '#calls' do
  it "returns an instance of #{described_class}::Calls" do
    peeek = described_class.new
    peeek.calls.should be_a(Peeek::Calls)
  end

  it "returns an empty calls if hooks aren't registered" do
    peeek = described_class.new
    peeek.calls.should be_empty
  end

  it 'returns calls of the registered hooks' do
    peeek = described_class.new
    peeek.hook(String, :%, :index)
    peeek.calls.should be_empty # assert
    '%s (%d)' % ['Koyomi', 18]
    'abc'.index('x')
    peeek.hooks.get(String, :%).calls.should have(1).items
    peeek.hooks.get(String, :index).calls.should have(1).items
    peeek.calls.should have(2).items
  end
end

describe Peeek, '#hook' do
  before do
    @peeek = described_class.new
    @peeek.hook(String, :%, :index)
  end

  after do
    @peeek.release
  end

  it "calls #{described_class}::Hook.create with the object, the method specification and the block" do
    block = lambda { }
    Peeek::Hook.should_receive(:create).with($stdout, :write, &block).and_return(hook_stub)
    Peeek::Hook.should_receive(:create).with(Numeric, :abs, &block).and_return(hook_stub)
    @peeek.hook($stdout, :write, &block)
    @peeek.hook(Numeric, :abs, &block)
  end

  it "returns an instance of #{described_class}::Calls" do
    hooks = @peeek.hook($stdout, :write)
    hooks.should be_a(Peeek::Hooks)
  end

  it "returns registered hooks at calling" do
    hooks = @peeek.hook($stdout, :write)
    hooks.should have(1).items
    hooks.get($stdout, :write).should_not be_nil
  end

  it 'links a hook to the method' do
    hook = @peeek.hook($stdout, :write).get($stdout, :write)
    hook.should be_linked
  end

  it "starts supervision for instance method if the method isn't defined yet" do
    String.should_not be_supervised_for_instance # assert
    @peeek.hook(String, :undefined_method)
    String.should be_supervised_for_instance

    Numeric.should_not be_supervised_for_instance # assert
    @peeek.hook(Numeric, :abs)
    Numeric.should_not be_supervised_for_instance
  end

  it "starts supervision for singleton method if the method isn't defined yet" do
    $stdout.should_not be_supervised_for_singleton # assert
    @peeek.hook($stdout, :undefined_method)
    $stdout.should be_supervised_for_singleton

    Regexp.should_not be_supervised_for_singleton # assert
    @peeek.hook(Regexp, '.quote')
    Regexp.should_not be_supervised_for_singleton
  end

  it "adds hooks to the registered hooks" do
    hook = @peeek.hook($stdout, :write).get($stdout, :write)
    @peeek.hooks.should be_include(hook)
  end
end

describe Peeek, '#release' do
  before do
    @peeek = described_class.new
    @peeek.hook(String, :%, :undefined_method)
    @peeek.hook($stdout, :undefined_method)
  end

  it 'cleras the hooks' do
    @peeek.hooks.should_not be_empty # assert
    @peeek.release
    @peeek.hooks.should be_empty
  end

  it 'unlinks the hooks' do
    original_hooks = @peeek.hooks.dup
    one_or_more(original_hooks).should be_any { |hook|  hook.linked? } # assert
    @peeek.release
    one_or_more(original_hooks).should be_all { |hook| !hook.linked? }
  end

  it 'clears calls of the hooks' do
    '%s (%d)' % ['Koyomi', 18]
    original_hooks = @peeek.hooks.dup
    one_or_more(original_hooks).should be_any { |hook| !hook.calls.empty? } # assert
    @peeek.release
    one_or_more(original_hooks).should be_all { |hook|  hook.calls.empty? }
  end

  it 'revokes supervision for instance method' do
    String.should be_supervised_for_instance # assert
    @peeek.release
    String.should_not be_supervised_for_instance
  end

  it 'revokes supervision for singleton method' do
    $stdout.should be_supervised_for_singleton # assert
    @peeek.release
    $stdout.should_not be_supervised_for_singleton
  end

  it 'returns self' do
    @peeek.release.should equal(@peeek)
  end
end

describe Peeek, '#circumvent' do
  before do
    @peeek = described_class.new
  end

  after do
    @peeek.release
  end

  it 'unlinks the hooks only in the block' do
    @peeek.hook(String, :%)
    @peeek.hooks.get(String, :%).should be_linked # assert

    @peeek.circumvent do
      @peeek.hooks.get(String, :%).should_not be_linked
    end

    @peeek.hooks.get(String, :%).should be_linked
  end

  it 'revokes supervision for instance method only in the block' do
    @peeek.hook(String, :undefined_method)
    String.should be_supervised_for_instance # assert

    @peeek.circumvent do
      String.should_not be_supervised_for_instance
    end

    String.should be_supervised_for_instance
  end

  it 'revokes supervision for singleton method only in the block' do
    @peeek.hook($stdout, :undefined_method)
    $stdout.should be_supervised_for_singleton # assert

    @peeek.circumvent do
      $stdout.should_not be_supervised_for_singleton
    end

    $stdout.should be_supervised_for_singleton
  end

  it 'raises ArgumentError if a block not given' do
    lambda { @peeek.circumvent }.should raise_error(ArgumentError, 'block not supplied')
  end
end

describe Peeek::Readily, '#peeek' do
  it 'registers hooks to the current Peeek object' do
    Peeek.local do
      Peeek.current.should_receive(:hook).with(String, :%, :index)
      Peeek.current.should_receive(:hook).with(Numeric, :abs)
      String.peeek(:%, :index)
      Numeric.peeek(:abs)
    end
  end
end
