def hook_stub(attrs = {})
  stub('Peeek::Hook').tap do |s|
    calls = Array.new(attrs[:calls] || 0)
    defined = attrs[:defined] || true
    linked = attrs[:linked] || false

    s.stub!(:object => attrs[:object])
    s.stub!(:method_name => attrs[:method_name])
    s.stub!(:calls => calls)
    s.stub!(:defined?).and_return { defined }
    s.stub!(:linked?).and_return { linked }

    s.stub!(:link).and_return do
      linked = true
      s
    end

    s.stub!(:unlink).and_return do
      linked = false
      s
    end
  end
end

def instance_linker_stub(object, method_name)
  original_method = object.instance_method(method_name)
  linker = stub('Peeek::Hook::Linker', :target_method => original_method, :link => nil, :unlink => nil)
  [linker, original_method]
end

def call_stub(result, attrs = {})
  attrs = attrs.merge(
    :returned? => result == :return_value,
    :raised?   => result == :exception
  )

  stub('Peeek::Call', attrs)
end

def one_or_more(array)
  array.should_not be_empty
  array
end

class SupervisionMatcher
  def initialize(purpose)
    @purpose = purpose
  end

  def matches?(object)
    @object = object
    callback_name = {:instance => :method_added, :singleton => :singleton_method_added}[@purpose]
    method = object.method(callback_name)
    require 'ruby18_source_location' unless method.respond_to?(:source_location)
    source_location = method.source_location
    !!(source_location && source_location[0].include?('lib/peeek/supervisor.rb'))
  end

  def description
    "be supervised for #{@purpose} method"
  end

  def failure_message
    "#{@object.inspect} should be supervised for #{@purpose} method, but not supervised"
  end

  def negative_failure_message
    "#{@object.inspect} should not be supervised for #{@purpose} method, but supervised"
  end
end

def be_supervised_for_instance
  SupervisionMatcher.new(:instance)
end

def be_supervised_for_singleton
  SupervisionMatcher.new(:singleton)
end
