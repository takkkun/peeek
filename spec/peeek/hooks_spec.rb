require 'peeek/hooks'

def sample_hooks
  Peeek::Hooks.new([
    hook_stub(:object => String,  :method_name => :%,     :calls => 1, :linked => true),
    hook_stub(:object => Numeric, :method_name => :abs,   :calls => 0, :linked => false),
    hook_stub(:object => String,  :method_name => :index, :calls => 3, :linked => true)
  ])
end

describe Peeek::Hooks, '#get' do
  it 'returns a hook that corresponds to the object' do
    hooks = sample_hooks
    hooks.get(String).should == hooks[0]
    hooks.get(Numeric).should == hooks[1]
  end

  it "returns nil if a hook that corresponds to the object doesn't exist" do
    hooks = sample_hooks
    hooks.get(Regexp).should be_nil
  end

  context 'with a method name' do
    it 'returns a hook that corresponds to the object and the method name' do
      hooks = sample_hooks
      hooks.get(String, :%).should == hooks[0]
      hooks.get(Numeric, :abs).should == hooks[1]
      hooks.get(String, :index).should == hooks[2]
    end

    it "returns nil if a hook that corresponds to the object and the method name doesn't exist" do
      hooks = sample_hooks
      hooks.get(String, :rindex).should be_nil
    end
  end
end

describe Peeek::Hooks, '#clear' do
  it 'unlinks the hooks from the methods' do
    hooks = sample_hooks
    original_hooks = hooks.dup

    # assert
    original_hooks.should_not be_empty
    original_hooks.should be_any { |hook|  hook.linked? }

    hooks.clear
    original_hooks.should_not be_empty
    original_hooks.should be_all { |hook| !hook.linked? }
  end

  it 'clears calls of the hooks' do
    hooks = sample_hooks
    original_hooks = hooks.dup

    # assert
    original_hooks.should_not be_empty
    original_hooks.should be_any { |hook| !hook.calls.empty? }

    hooks.clear
    original_hooks.should_not be_empty
    original_hooks.should be_all { |hook|  hook.calls.empty? }
  end

  it 'clears the hooks' do
    hooks = sample_hooks
    hooks.clear
    hooks.should be_empty
  end

  it 'returns self' do
    hooks = sample_hooks
    hooks.clear.should be_equal(hooks)
  end
end

describe Peeek::Hooks, '#circumvent' do
  it 'unlinks the hooks from the methods in the block' do
    hooks = sample_hooks

    hooks.circumvent do
      hooks.should_not be_empty
      hooks.should be_all { |hook| !hook.linked? }
    end
  end

  it 'reverts state of the hooks after calling' do
    hooks = sample_hooks
    linked_hooks = hooks.select(&:linked?)
    unlinked_hooks = hooks.reject(&:linked?)

    # assert
    linked_hooks.should_not be_empty
    linked_hooks.should be_all { |hook| hook.linked? }
    unlinked_hooks.should_not be_empty
    unlinked_hooks.should be_all { |hook| !hook.linked? }

    hooks.circumvent { }
    linked_hooks.should_not be_empty
    linked_hooks.should be_all { |hook| hook.linked? }
    unlinked_hooks.should_not be_empty
    unlinked_hooks.should be_all { |hook| !hook.linked? }
  end

  it 'raises ArgumentError if a block not given' do
    hooks = sample_hooks
    lambda { hooks.circumvent }.should raise_error(ArgumentError, 'block not supplied')
  end
end
