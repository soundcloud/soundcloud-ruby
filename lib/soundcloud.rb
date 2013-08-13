require 'hashie'
require 'httmultiparty'
require 'uri'

require 'soundcloud/array_response_wrapper'
require 'soundcloud/client'
require 'soundcloud/hash_response_wrapper'
require 'soundcloud/response_error'
require 'soundcloud/version'

module SoundCloud

  def new(options={})
    Client.new(options)
  end
  module_function :new

end

Soundcloud = SoundCloud
