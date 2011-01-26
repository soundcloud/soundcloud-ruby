# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'soundcloud/version'
 
Gem::Specification.new do |s|
  s.name        = "soundcloud"
  s.rubyforge_project = "soundcloud"
  s.version     = Soundcloud::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Johannes Wagener"]
  s.email       = ["johannes@soundcloud.com"]
  s.homepage    = "http://dev.soundcloud.com"
  s.summary     = "A simple Soundcloud API wrapper"
  s.description = "A simple Soundcloud API wrapper based of httparty, multipart-post, httmultiparty"
 
  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency 'httparty', '>= 0.7.3'
  s.add_dependency 'httmultiparty'
  s.add_dependency 'hashie'

  s.add_development_dependency "rspec"
  s.add_development_dependency "fakeweb"
 
  s.files        = Dir.glob("{lib}/**/*") + %w(README.md)
  s.require_path = 'lib'
end