def hook_stub(attrs = {})
  stub('Peeek::Hook').tap do |s|
    attrs[:calls]  ||= 0
    attrs[:linked] ||= false

    s.stub!(:object => attrs[:object])
    s.stub!(:method_name => attrs[:method_name])
    s.stub!(:calls).and_return { Array.new(attrs[:calls]) }
    s.stub!(:linked?).and_return { attrs[:linked] }

    s.stub!(:link).and_return do
      attrs[:linked] = true
      s
    end

    s.stub!(:unlink).and_return do
      attrs[:linked] = false
      s
    end

    s.stub!(:clear).and_return do
      attrs[:calls] = 0
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
