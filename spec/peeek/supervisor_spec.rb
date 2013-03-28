require 'spec_helper'
require 'peeek/supervisor'

def sample_supervisor
  Peeek::Supervisor.create_for_instance.tap do |supervisor|
    supervisor << hook_stub(:object => String,  :method_name => :capitalize)
    supervisor << hook_stub(:object => Numeric, :method_name => :days)
    supervisor << hook_stub(:object => String,  :method_name => :singularize)
  end
end

describe Peeek::Supervisor, '.create_for_instance' do
  it "calls #{described_class}.new with :method_added" do
    described_class.should_receive(:new).with(:method_added)
    described_class.create_for_instance
  end

  it "returns an instance of #{described_class}" do
    supervisor = described_class.create_for_instance
    supervisor.should be_a(described_class)
  end
end

describe Peeek::Supervisor, '.create_for_singleton' do
  it "calls #{described_class}.new with :singleton_method_added" do
    described_class.should_receive(:new).with(:singleton_method_added)
    described_class.create_for_singleton
  end

  it "returns an instance of #{described_class}" do
    supervisor = described_class.create_for_singleton
    supervisor.should be_a(described_class)
  end
end

describe Peeek::Supervisor, '#add' do
  before do
    @supervisor = sample_supervisor
  end

  after do
    @supervisor.clear
  end

  it 'adds the hook to the supervisor' do
    hook = hook_stub(:object => String)
    @supervisor.add(hook)
    @supervisor.hooks.should be_include(hook)
  end

  it 'starts supervision to the object of the hook' do
    supervised?(Regexp).should be_false # assert
    hook = hook_stub(:object => Regexp)
    @supervisor.add(hook)
    @supervisor.original_callbacks.should be_include(Regexp)
    supervised?(Regexp).should be_true
  end

  it "doesn't start supervision to object that is supervising already" do
    hook = hook_stub(:object => String)
    original_callback = @supervisor.original_callbacks[String]
    @supervisor.add(hook)
    @supervisor.original_callbacks[String].should be_equal(original_callback)
  end

  it 'returns self' do
    hook = hook_stub(:object => String)
    @supervisor.add(hook).should be_equal(@supervisor)
  end
end

describe Peeek::Supervisor, '#clear' do
  it 'clears the hooks in the supervisor' do
    supervisor = sample_supervisor
    supervisor.hooks.should_not be_empty # assert
    supervisor.clear
    supervisor.hooks.should be_empty
  end

  it 'clears the original callbacks in the supervisor' do
    supervisor = sample_supervisor
    supervisor.original_callbacks.should_not be_empty # assert
    supervisor.clear
    supervisor.original_callbacks.should be_empty
  end

  it 'revokes supervision to the objects' do
    supervisor = sample_supervisor
    supervised?(String).should be_true # assert
    supervised?(Numeric).should be_true # assert
    supervisor.clear
    supervised?(String).should be_false
    supervised?(Numeric).should be_false
  end

  it 'returns self' do
    supervisor = sample_supervisor
    supervisor.clear.should be_equal(supervisor)
  end
end

describe Peeek::Supervisor, '#circumvent' do
  before do
    @supervisor = sample_supervisor
  end

  after do
    @supervisor.clear
  end

  it 'revokes supervision to the objects in the block' do
    @supervisor.circumvent do
      supervised?(String).should be_false
      supervised?(Numeric).should be_false
    end
  end

  it 'restarts supervision to the objects after calling' do
    supervised?(String).should be_true # assert
    supervised?(Numeric).should be_true # assert
    @supervisor.circumvent { }
    supervised?(String).should be_true
    supervised?(Numeric).should be_true
  end

  it 'raises ArgumentError if a block not given' do
    lambda { @supervisor.circumvent }.should raise_error(ArgumentError, 'block not supplied')
  end
end
