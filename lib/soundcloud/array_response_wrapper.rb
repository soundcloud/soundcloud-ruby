class Soundcloud::ArrayResponseWrapper < Array
  attr_reader :response
  def initialize(response)
    mashes = response.map { |o| Hashie::Mash.new(o) }
    self.replace(mashes)
    @response = response
  end
end