require 'peeek/hook/linker'

describe Peeek::Hook::Linker, '.classes' do
  before do
    @class = Class.new(described_class)
  end

  after do
    described_class.classes.delete(@class)
  end

  it "returns classes that inherited #{described_class}" do
    described_class.classes.should be_include(@class)
  end
end
