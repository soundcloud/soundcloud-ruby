module SoundCloud
  class HashResponseWrapper < Hashie::Mash
    attr_reader :response
    def initialize(response=nil, *args)
      @response = response
      super(response, *args)
    end
  end
end
