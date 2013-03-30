def hook_stub(attrs = {})
  stub('Peeek::Hook').tap do |s|
    calls = Array.new(attrs[:calls] || 0)
    linked = attrs[:linked] || false

    s.stub!(:object => attrs[:object])
    s.stub!(:method_name => attrs[:method_name])
    s.stub!(:calls => calls)
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
  linker = stub('Peeek::Hook::Linker', :link => original_method, :unlink => nil)
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
  def initialize(callback_name)
    @callback_name = callback_name
  end

  def matches?(object)
    @object = object
    source_location = object.method(@callback_name).source_location
    !!(source_location && source_location[0].include?('lib/peeek/supervisor.rb'))
  end

  def failure_message
    "#{@object.inspect} should be supervised, but not supervised"
  end

  def negative_failure_message
    "#{@object.inspect} should not be supervised, but supervised"
  end

  private

  def purpose
    {:method_added => 'instance', :singleton_method_added => 'singleton'}[@callback_name]
  end
end

def be_supervised_for_instance
  SupervisionMatcher.new(:method_added)
end

def be_supervised_for_singleton
  SupervisionMatcher.new(:singleton_method_added)
end
