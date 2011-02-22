require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe Soundcloud::HashResponseWrapper do
  describe '.new' do
    it "should provide a Mash with accessors for the key/values of the passed response" do
      Soundcloud::HashResponseWrapper.new({:foo => 'bar'}).foo.should == 'bar'
    end
    
    it "should not have nil accessors for non present keys" do
      Soundcloud::HashResponseWrapper.new({:foo => 'bar'}).should raise_error
    end
    
  end
  
  describe '#response' do
    it "should return the original response object" do
      Soundcloud::HashResponseWrapper.new({:foo => 'bar'}).response.should == {:foo => 'bar'}
    end
  end
end