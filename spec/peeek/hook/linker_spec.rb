require 'peeek/hook/linker'

describe Peeek::Hook::Linker, '.classes' do
  it "returns classes that inherited #{described_class}" do
    klass = Class.new(described_class)
    described_class.classes.should be_include(klass)
  end
end
