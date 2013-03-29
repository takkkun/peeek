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

def call_stub(result, attrs = {})
  attrs = attrs.merge(
    :returned? => result == :return_value,
    :raised?   => result == :exception
  )

  stub('Peeek::Call', attrs)
end

def supervised?(object)
  supervised_by?(object, :method_added) or supervised_by?(object, :singleton_method_added)
end

def supervised_by?(object, callback_name)
  source_location = object.method(callback_name).source_location
  !!(source_location && source_location[0].include?('lib/peeek/supervisor.rb'))
end

def one_or_more(array)
  array.should_not be_empty
  array
end
