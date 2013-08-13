require 'helper'

describe Soundcloud::ArrayResponseWrapper do

  before do
    @array_response_wrapper = Soundcloud::ArrayResponseWrapper.new([{:foo => 'bar'}])
  end

  describe '.new' do
    it "provides a Mash with accessors for the key/values of each item of the passed response" do
      expect(@array_response_wrapper.first.foo).to eq('bar')
    end
  end

  describe '#response' do
    it "returns the original response object" do
      expect(@array_response_wrapper.response).to be_an Array
      expect(@array_response_wrapper.response).to eq([{:foo => 'bar'}])
    end
  end

end
