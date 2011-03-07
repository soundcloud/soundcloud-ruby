begin
  require 'bundler'
rescue LoadError
  puts 'although not required, bundler is recommended during development'
end

require 'soundcloud'

#require 'spec/autorun'
require 'fakeweb'

def file_fixture(filename)
  open(File.join(File.dirname(__FILE__), 'fixtures', "#{filename.to_s}")).read
end

RSpec.configure do |config|
  config.before { FakeWeb.allow_net_connect = false }
  config.after  { FakeWeb.allow_net_connect = true }
end
