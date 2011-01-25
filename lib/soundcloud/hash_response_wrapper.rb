class Soundcloud::HashResponseWrapper < Mash
  attr_reader :response
  def initialize(response)
    super(response)
    @response = response
  end
end
