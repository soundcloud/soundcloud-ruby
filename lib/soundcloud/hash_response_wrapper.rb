class Soundcloud::HashResponseWrapper < Hashie::Mash
  attr_reader :response
  def initialize(response=nil, *args)
    super(response, *args)
    @response = response
  end
end
