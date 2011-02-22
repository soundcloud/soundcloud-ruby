class Soundcloud::HashResponseWrapper < Hashie::Mash
  attr_reader :response
  def initialize(response, *args)
    super(response, *args) do |x| 
      raise NoMethodError
    end
    @response = response
  end
end
