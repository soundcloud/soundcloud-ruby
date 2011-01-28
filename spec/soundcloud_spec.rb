require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Soundcloud do
  METHODS = [:get, :post, :put, :delete, :head]
  it "should raise ArgumentError when initialized with no options" do
    lambda do
      Soundcloud.new
    end.should raise_error ArgumentError
  end

  context 'initialized with a client id' do
    subject { Soundcloud.new(:client_id => 'client') }
    its(:client_id)       { should == 'client' }
    its(:use_ssl?)        { should be_false }
    its(:site)            { should == 'soundcloud.com' }
    its(:host)            { should == 'soundcloud.com' }
    its(:api_host)        { should == 'api.soundcloud.com' }

    METHODS.each do |method|
      describe "##{method}" do
        it "should accept urls as path and rewrite them" do
          Soundcloud.should_receive(method).with('http://api.soundcloud.com/tracks/123', {:query => {:consumer_key => 'client'}})
          subject.send(method, 'http://api.soundcloud.com/tracks/123')
        end

        it "should preserve query string in path" do
          FakeWeb.register_uri(method, "http://api.soundcloud.com/tracks?consumer_key=client&created_with_app_id=124", :body => "[{'title': 'bla'}]", :content_type => "application/json")
          subject.send(method, '/tracks?created_with_app_id=124').should be_an_instance_of Soundcloud::ArrayResponseWrapper
        end
        
        it "should pass the client_id as consumer_key (LEGACY) to .#{method}" do
          # TODO fix when api is ready for client_id
          Soundcloud.should_receive(method).with('http://api.soundcloud.com/tracks', {:query => {:consumer_key => 'client', :limit => 2}})
          subject.send(method, '/tracks', :limit => 2)
        end
        
        it "should wrap the response object in a Response" do
          FakeWeb.register_uri(method, "http://api.soundcloud.com/tracks/123?consumer_key=client", :body => "{'title': 'bla'}", :content_type => "application/json")
          subject.send(method, '/tracks/123').should be_an_instance_of Soundcloud::HashResponseWrapper
        end

        it "should wrap the response array in an array of ResponseMash" do
          FakeWeb.register_uri(method, "http://api.soundcloud.com/tracks?consumer_key=client", :body => "[{'title': 'bla'}]", :content_type => "application/json")
          subject.send(method, '/tracks').should be_an_instance_of Soundcloud::ArrayResponseWrapper
        end

        it "should raise an error if request not successful" do
          FakeWeb.register_uri(method, "http://api.soundcloud.com/tracks?consumer_key=client", :status => ["402", "Payment required"])
          lambda do
            subject.send(method, '/tracks')
          end.should raise_error Soundcloud::ResponseError
        end
      end
    end
  
    context 'and site = sandbox-soundcloud.com' do
      subject { Soundcloud.new(:client_id => 'client', :site => 'sandbox-soundcloud.com') }
      its(:site)     { should == 'sandbox-soundcloud.com' }
      its(:host)     { should == 'sandbox-soundcloud.com' }
      its(:api_host) { should == 'api.sandbox-soundcloud.com' }
    end
  end

  describe "#exchange_token" do
    it "should raise an argument error if client_secret no present" do
      lambda do
        Soundcloud.new(:client_id => 'x').exchange_token(:refresh_token => 'as')  
      end.should raise_error ArgumentError
    end

    it "should raise a response error when exchanging token results in 401" do
      lambda do
        FakeWeb.register_uri(:post, 
          "https://api.soundcloud.com/oauth2/token?grant_type=refresh_token&refresh_token=as&client_id=x&client_secret=bang", 
          :status => [401, "Unauthorized"],
          :body => '{error: "invalid_client"}', 
          :content_type => "application/json"
        )
        Soundcloud.new(:client_id => 'x', :client_secret => 'bang').exchange_token(:refresh_token => 'as')
      end.should raise_error Soundcloud::ResponseError
    end


    context "when initialized with client_id, client_secret" do
      let(:fake_token_response) { {'access_token' => 'ac', 'expires_in' => 3600, 'scope' => 3600, 'refresh_token' => 'ref'} }
      before do
        fake_token_response.stub!(:success?).and_return(true)
      end
      
      subject { Soundcloud.new(:client_id => 'client', :client_secret => 'secret') }

      it "should store the passed options" do
        subject.class.stub!(:post).and_return(fake_token_response)
        subject.exchange_token(:refresh_token => 'refresh')
        subject.refresh_token.should == 'ref'
      end

      it "should raise an error if response is a 401 not"

      it "should call authorize endpoint to exchange token and store them when refresh token is passed" do
        subject.class.stub!(:post)
        Soundcloud.should_receive(:post).with('https://api.soundcloud.com/oauth2/token', :query => {
          :grant_type     => 'refresh_token',
          :refresh_token  => 'refresh',
          :client_id      => 'client',
          :client_secret  => 'secret'
        }).and_return(fake_token_response)
        subject.exchange_token(:refresh_token => 'refresh')
        subject.access_token.should  == 'ac'
        subject.refresh_token.should == 'ref'
      end

      it "should call authorize endpoint to exchange token and store them when credentials are passed" do
        Soundcloud.should_receive(:post).with('https://api.soundcloud.com/oauth2/token', :query => {
          :grant_type     => 'password',
          :username       => 'foo@bar.com',
          :password       => 'pass',
          :client_id      => 'client',
          :client_secret  => 'secret',
        }).and_return(fake_token_response)
        subject.exchange_token(:username => 'foo@bar.com', :password => 'pass')
        subject.access_token.should  == 'ac'
        subject.refresh_token.should == 'ref'
      end
    
      it "should call authorize endpoint to exchange token and store them when code and redirect_uri are passed" do
        subject.class.should_receive(:post).with('https://api.soundcloud.com/oauth2/token', :query => {
          :grant_type     => 'authorization_code',
          :redirect_uri   => 'http://somewhere.com/bla',
          :code       => 'pass',
          :client_id      => 'client',
          :client_secret  => 'secret',
        }).and_return(fake_token_response)
        subject.exchange_token(:redirect_uri   => 'http://somewhere.com/bla', :code => 'pass')
        subject.access_token.should  == 'ac'
        subject.refresh_token.should == 'ref'
      end
    end
  end

  context 'initialized with access_token, refresh_token' do
    subject { Soundcloud.new(:access_token => 'ac', :refresh_token => 'ce', :client_id => 'client', :client_secret => 'sect') }
    its(:access_token)    { should == 'ac' }
    its(:use_ssl?)        { should be_true }
    
    METHODS.each do |method|
      describe "##{method}" do
        it "should pass the oauth_token parameter when doing a request" do
          Soundcloud.should_receive(method).with('https://api.soundcloud.com/tracks', {:query => {:oauth_token => 'ac'}})
          subject.send(method, '/tracks')
        end

        it "should try to refresh the token if it is expired and retry" do
          FakeWeb.register_uri(method, "https://api.soundcloud.com/tracks/1?oauth_token=ac", :status => ['401', "Unauthorized"], :body => "{'error': 'invalid_grant'}", :content_type => "application/json")
          FakeWeb.register_uri(:post, 
            "https://api.soundcloud.com/oauth2/token?grant_type=refresh_token&refresh_token=ce&client_id=client&client_secret=sect", 
            :body => '{"access_token":  "new_access_token", "expires_in": 3600, "scope": null, "refresh_token": "04u7h-r3fr35h-70k3n"}', 
            :content_type => "application/json"
          )

          FakeWeb.register_uri(method, "https://api.soundcloud.com/tracks/1?oauth_token=new_access_token", :body => "{'title': 'test'}", :content_type => "application/json")

          lambda do 
            response = subject.send(method, '/tracks/1')
            response.title.should == 'test'
          end.should change { subject.access_token }.to('new_access_token')
        end
      end
    end
  end
end
