require 'helper'

describe SoundCloud::HashResponseWrapper do

  before do
    @hash_response_wrapper = SoundCloud::HashResponseWrapper.new({:foo => 'bar'})
  end

  describe '.new' do
    it "provides a Mash with accessors for the key/values of the passed response" do
      expect(@hash_response_wrapper.foo).to eq('bar')
    end
  end

  describe '#response' do
    it "returns the original response object" do
      expect(@hash_response_wrapper.response).to be_a Hash
      expect(@hash_response_wrapper.response).to eq({:foo => 'bar'})
    end
  end

end
