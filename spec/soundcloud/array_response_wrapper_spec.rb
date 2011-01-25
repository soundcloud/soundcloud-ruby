require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe Soundcloud::ArrayResponseWrapper do
  describe '.new' do
    it "should provide a Mash with accessors for the key/values of each item of the passed response" do
      Soundcloud::ArrayResponseWrapper.new([{:foo => 'bar'}]).first.foo.should == 'bar'
    end
  end
  
  describe '#response' do
    it "should return the original response object" do
      Soundcloud::ArrayResponseWrapper.new([{:foo => 'bar'}]).response.should == [{:foo => 'bar'}]
    end
  end

end