# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'peeek/version'

Gem::Specification.new do |spec|
  spec.name                  = 'peeek'
  spec.version               = Peeek::VERSION
  spec.authors               = ['Takahiro Kondo']
  spec.email                 = ['heartery@gmail.com']
  spec.description           = %q{Peek at calls of a method}
  spec.summary               = spec.description
  spec.homepage              = 'https://github.com/takkkun/peeek'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 1.8.7'

  spec.files                 = `git ls-files`.split($/)
  spec.executables           = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files            = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths         = ['lib']

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
