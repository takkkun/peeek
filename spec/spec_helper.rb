def call_stub(result, attrs = {})
  attrs = attrs.merge(
    :returned? => result == :return_value,
    :raised?   => result == :exception
  )

  stub('Peeek::Call', attrs)
end
