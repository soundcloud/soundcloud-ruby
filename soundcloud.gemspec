# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'soundcloud/version'

Gem::Specification.new do |spec|
  spec.name        = 'soundcloud'
  spec.version     = Soundcloud::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ["Johannes Wagener"]
  spec.email       = ["johannes@soundcloud.com"]
  spec.homepage    = 'http://dev.soundcloud.com'
  spec.summary     = "A simple Soundcloud API wrapper"
  spec.description = spec.summary

  spec.required_rubygems_version = '>= 1.3.5'

  spec.add_dependency('httparty',      '~> 0.11.0')
  spec.add_dependency('httmultiparty', '~> 0.3.0')
  spec.add_dependency('hashie', '~> 2.0')

  spec.add_development_dependency('bundler', '~> 1.0')

  spec.files        = Dir.glob("lib/**/*") + %w(README.md)
  spec.require_path = 'lib'
end
