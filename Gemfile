source 'http://rubygems.org'

gem 'rake', '>= 10.1'

group :test do
  gem 'json', :platforms => :ruby_18
  gem 'rspec', '>= 2.14'
  gem 'simplecov', '>= 0.7'
  gem 'webmock', '>= 1.13'
end

platforms :ruby_18 do
  gem 'httparty', '~> 0.11.0'
end

gemspec
