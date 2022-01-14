require 'helper'

describe SoundCloud do
  it "raises ArgumentError when initialized with no options" do
    expect do
      SoundCloud.new
    end.to raise_error(ArgumentError)
  end

  context 'initialized with a client id' do
    subject{SoundCloud.new(:client_id => 'client')}

    describe "#client_id" do
      it "returns the initialized value" do
        expect(subject.client_id).to eq("client")
      end
    end

    describe "#options" do
      it "includes client_id" do
        expect(subject.options).to include(:client_id)
      end
    end

    describe "#use_ssl?" do
      it "is false" do
        expect(subject.use_ssl?).to be false
      end
    end

    describe "#site" do
      it "is soundcloud.com" do
        expect(subject.site).to eq("soundcloud.com")
      end
    end

    describe "#host" do
      it "is soundcloud.com" do
        expect(subject.host).to eq("soundcloud.com")
      end
    end

    describe "#api_host" do
      it "is api.soundcloud.com" do
        expect(subject.api_host).to eq("api.soundcloud.com")
      end
    end

    [:get, :delete, :head].each do |method|
      describe "##{method}" do
        it "accepts urls as path and rewrite them" do
          expect(SoundCloud::Client).to receive(method).with('http://api.soundcloud.com/tracks/123', {:query => {:format => "json", :client_id => 'client'}})
          subject.send(method, 'http://api.soundcloud.com/tracks/123')
        end

        it "preserves query string in path" do
          stub_request(method, "http://api.soundcloud.com/tracks").
            with(:query => {:client_id => "client", :created_with_app_id => "124", :format => "json"}).
            to_return(:body => '[{"title": "bla"}]', :headers => {:content_type => "application/json"})
          expect(subject.send(method, '/tracks?created_with_app_id=124')).to be_an_instance_of SoundCloud::ArrayResponseWrapper
        end

        it "passes the client_id as client_id (LEGACY) to .#{method}" do
          expect(SoundCloud::Client).to receive(method).with('http://api.soundcloud.com/tracks', {:query => {:client_id => 'client', :limit => 2, :format => "json"}})
          subject.send(method, '/tracks', :limit => 2)
        end

        it "wraps the response object in a Response" do
          stub_request(method, "http://api.soundcloud.com/tracks/123").
            with(:query => {:format => "json", :client_id => "client"}).
            to_return(:body => '{"title": "bla"}', :headers => {:content_type => "application/json"})
          expect(subject.send(method, '/tracks/123')).to be_an_instance_of SoundCloud::HashResponseWrapper
        end

        it "wraps the response array in an array of ResponseMash" do
          stub_request(method, "http://api.soundcloud.com/tracks").
            with(:query => {:format => "json", :client_id => "client"}).
            to_return(:body => '[{"title": "bla"}]', :headers => {:content_type => "application/json"})
          expect(subject.send(method, '/tracks')).to be_an_instance_of SoundCloud::ArrayResponseWrapper
        end

        it "raises an error if request not successful" do
          stub_request(method, "http://api.soundcloud.com/tracks").
            with(:query => {:format => "json", :client_id => "client"}).
            to_return(:status => 402, :body => "{'error': 'you need to pay'}")
          expect do
            subject.send(method, '/tracks')
          end.to raise_error(SoundCloud::ResponseError)
        end

        it "sends a user agent header" do
          stub_request(method, "http://api.soundcloud.com/tracks").
            with(:query => {:format => "json", :client_id => "client"})
          subject.send(method, '/tracks')
          expect(WebMock.last_request.headers["User-Agent"]).to eq("SoundCloud Ruby Wrapper #{SoundCloud::VERSION}")
        end
      end
    end

    [:post, :put].each do |method|
      describe "##{method}" do
        it "accepts urls as path and rewrite them" do
          expect(SoundCloud::Client).to receive(method).with('http://api.soundcloud.com/tracks/123', {:body => {:format => "json", :client_id => 'client'}})
          subject.send(method, 'http://api.soundcloud.com/tracks/123')
        end

        it "preserves query string in path" do
          stub_request(method, "http://api.soundcloud.com/tracks").
            with(:query => {:created_with_app_id => "124"}).
            to_return(:body => '[{"title": "bla"}]', :headers => {:content_type => "application/json"})
          expect(subject.send(method, '/tracks?created_with_app_id=124')).to be_an_instance_of SoundCloud::ArrayResponseWrapper
        end

        it "passes the client_id as client_id (LEGACY) to .#{method}" do
          expect(SoundCloud::Client).to receive(method).with('http://api.soundcloud.com/tracks', {:body => {:limit => 2, :format => "json", :client_id => 'client'}})
          subject.send(method, '/tracks', :limit => 2)
        end

        it "wraps the response object in a Response" do
          stub_request(method, "http://api.soundcloud.com/tracks/123").
            to_return(:body => '{"title": "bla"}', :headers => {:content_type => "application/json"})
          expect(subject.send(method, '/tracks/123')).to be_an_instance_of SoundCloud::HashResponseWrapper
        end

        it "wraps the response array in an array of ResponseMash" do
          stub_request(method, "http://api.soundcloud.com/tracks").
            to_return(:body => '[{"title": "bla"}]', :headers => {:content_type => "application/json"})
          expect(subject.send(method, '/tracks')).to be_an_instance_of SoundCloud::ArrayResponseWrapper
        end

        it "raises an error if request not successful" do
          stub_request(method, "http://api.soundcloud.com/tracks").
            to_return(:status => 402)
          expect do
            subject.send(method, '/tracks')
          end.to raise_error(SoundCloud::ResponseError)
        end
      end
    end

    describe "#authorize_url" do
      it "generates a authorize_url" do
        expect(subject.authorize_url(:redirect_uri => "http://come.back.to/me")).to eq("https://api.soundcloud.com/connect?response_type=code&client_id=client&redirect_uri=http://come.back.to/me&")
      end

      it "generates a authorize_url and include the passed display parameter" do
        expect(subject.authorize_url(:redirect_uri => "http://come.back.to/me", :display => "popup")).to eq("https://api.soundcloud.com/connect?response_type=code&client_id=client&redirect_uri=http://come.back.to/me&display=popup")
      end

      it "generates a authorize_url and include the passed state parameter" do
        expect(subject.authorize_url(:redirect_uri => "http://come.back.to/me", :state => "hell&yeah")).to eq("https://api.soundcloud.com/connect?response_type=code&client_id=client&redirect_uri=http://come.back.to/me&state=hell%26yeah")
      end

      it "generates a authorize_url and include the passed scope parameter" do
        expect(subject.authorize_url(:redirect_uri => "http://come.back.to/me", :scope => "email")).to eq("https://api.soundcloud.com/connect?response_type=code&client_id=client&redirect_uri=http://come.back.to/me&scope=email")
      end

      it "generates a authorize_url and include the passed scope and state parameter" do
        expect(subject.authorize_url(:redirect_uri => "http://come.back.to/me", :scope => "email", :state => "blub")).to eq("https://api.soundcloud.com/connect?response_type=code&client_id=client&redirect_uri=http://come.back.to/me&state=blub&scope=email")
      end
    end

    describe "#on_exchange_token" do
      it "stores the passed block as option" do
        block = Proc.new{}
        subject.on_exchange_token(&block)
        expect(subject.instance_variable_get(:@options)[:on_exchange_token]).to eq(block)
      end
    end

    describe "#expired?" do
      it "is true if expires_at is in the past" do
        subject.instance_variable_get(:@options)[:expires_at] = Time.now - 60
        expect(subject).to be_expired
      end
      it "is false if expires_at is in the future" do
        subject.instance_variable_get(:@options)[:expires_at] = Time.now + 60
        expect(subject).not_to be_expired
      end
    end
  end

  describe "#exchange_token" do
    it "raises an argument error if client_secret no present" do
      expect do
        SoundCloud.new(:client_id => 'x').exchange_token(:refresh_token => 'as')
      end.to raise_error(ArgumentError)
    end

    it "raises a response error when exchanging token results in 401" do
      stub_request(:post, "https://api.soundcloud.com/oauth2/token").
        with(:body => {:grant_type => "client_credentials", :client_id => "x", :client_secret => "bang"}).
        to_return(:status => 200, :body => '{"access_token":"ac","refresh_token":"as"}', :headers => {:content_type => "application/json"})

      stub_request(:post, "https://api.soundcloud.com/oauth2/token").
        with(:body => {:grant_type => "refresh_token", :refresh_token => "as", :client_id => "x", :client_secret => "bang"}).
        to_return(:status => 401, :body => '{error: "invalid_client"}', :headers => {:content_type => "application/json"})

      expect do
        SoundCloud.new(:client_id => 'x', :client_secret => 'bang').exchange_token(:refresh_token => 'as')
      end.to raise_error(SoundCloud::ResponseError)
    end


    context "when initialized with client_id, client_secret" do
      let(:fake_token_response){{'access_token' => 'ac', 'expires_in' => 3600, 'scope' => "*", 'refresh_token' => 'ref'}}
      before do
        allow(fake_token_response).to receive(:success?).and_return(true)
        stub_request(:post, "https://api.soundcloud.com/oauth2/token").
          with(:body => {:grant_type => "client_credentials", :client_id => "client", :client_secret => "secret"}).
          to_return(:status => 200, :body => '{"access_token":"ac","refresh_token":null}', :headers => {:content_type => "application/json"})
      end

      subject { SoundCloud.new(:client_id => 'client', :client_secret => 'secret') }

      it "stores the passed options" do
        allow(subject.class).to receive(:post).and_return(fake_token_response)
        subject.exchange_token(:refresh_token => 'refresh')
        expect(subject.refresh_token).to eq('ref')
      end

      it "calls authorize endpoint to exchange token and store them when refresh token is passed" do
        allow(subject.class).to receive(:post)
        expect(SoundCloud::Client).to receive(:post).with('https://api.soundcloud.com/oauth2/token', :query => {
          :grant_type    => 'refresh_token',
          :refresh_token => 'refresh',
          :client_id     => 'client',
          :client_secret => 'secret'
        }).and_return(fake_token_response)
        subject.exchange_token(:refresh_token => 'refresh')
        expect(subject.access_token).to eq('ac')
        expect(subject.refresh_token).to eq('ref')
      end

      it "calls authorize endpoint to exchange token and store them when client credentials are passed" do
        subject
        expect(SoundCloud::Client).to receive(:post).with('https://api.soundcloud.com/oauth2/token', :query => {
          :grant_type    => 'client_credentials',
          :client_id     => 'client',
          :client_secret => 'secret',
        }).and_return(fake_token_response)
        subject.exchange_token()
        expect(subject.access_token).to eq('ac')
        expect(subject.refresh_token).to eq('ref')
      end

      it "calls authorize endpoint to exchange token and store them when code and redirect_uri are passed" do
        expect(subject.class).to receive(:post).with('https://api.soundcloud.com/oauth2/token', :query => {
          :grant_type    => 'authorization_code',
          :redirect_uri  => 'http://somewhere.com/bla',
          :code          => 'pass',
          :client_id     => 'client',
          :client_secret => 'secret',
        }).and_return(fake_token_response)
        subject.exchange_token(:redirect_uri => 'http://somewhere.com/bla', :code => 'pass')
        expect(subject.access_token).to eq('ac')
        expect(subject.refresh_token).to eq('ref')
      end

      it "calls the on_exchange_token callback if it refreshes a token" do
        allow(subject.class).to receive(:post).and_return(fake_token_response)
        called = false
        subject.on_exchange_token{|soundcloud| expect(soundcloud).to eq(subject); called = true}
        subject.exchange_token(:username => 'foo@bar.com', :password => 'pass')
        expect(called).to be true
      end

      it "sets expires_at based on expire_in response" do
        allow(subject.class).to receive(:post).and_return(fake_token_response)
        subject.exchange_token(:username => 'foo@bar.com', :password => 'pass')
        expect(subject.expires_at.to_i).to eq((Time.now + 3600).to_i)
      end
    end
  end

  context 'initialized with access_token' do
    subject{SoundCloud.new(:access_token => 'ac', :client_id => 'client', :client_secret => 'sect')}

    describe "#get" do
      it "raises InvalidAccessTokenException when access token is invalid" do
        stub_request(:get, "https://api.soundcloud.com/me?format=json").
          to_return(:status => 401)
        expect do
          subject.send(:get, '/me')
        end.to raise_error(SoundCloud::ResponseError)
      end
    end
  end

  context 'initialized with access_token, refresh_token' do
    subject{SoundCloud.new(:access_token => 'ac', :refresh_token => 'ce', :client_id => 'client', :client_secret => 'sect')}

    describe "#access_token" do
      it "returns the initialized value" do
        expect(subject.access_token).to eq("ac")
      end
    end

    describe "#use_ssl?" do
      it "to be true" do
        expect(subject.use_ssl?).to be true
      end
    end

    [:get, :head, :delete].each do |method|
      describe "##{method}" do
        it "passes the Authorization header when doing a request" do
          expect(SoundCloud::Client).to receive(method).with('https://api.soundcloud.com/tracks', {:query => {:format => "json"}, :headers => { 'Authorization' => 'OAuth ac' }})
          subject.send(method, '/tracks')
        end

        it "tries to refresh the token if it is expired and retry" do
          stub_request(method, "https://api.soundcloud.com/tracks/1").
            with(:query => {:format => "json"}, :headers => { 'Authorization' => 'OAuth ac' }).
            to_return(:status => 401, :body => '{"error": "invalid_grant"}', :headers => {:content_type => "application/json"})

          stub_request(:post, "https://api.soundcloud.com/oauth2/token").
            with(:body => {:grant_type => "refresh_token", :refresh_token => "ce", :client_id => "client", :client_secret => "sect"}).
            to_return(:body => '{"access_token":"new_access_token","expires_in":3600,"scope":null,"refresh_token":"04u7h-r3fr35h-70k3n"}', :headers => {:content_type => "application/json"})

          stub_request(method, "https://api.soundcloud.com/tracks/1").
            with(:query => { :format => "json" }, :headers => { 'Authorization' => 'OAuth new_access_token' }).
            to_return(:body => '{"title": "test"}', :headers => {:content_type => "application/json"})

          expect do
            response = subject.send(method, '/tracks/1')
            expect(response.title).to eq('test')
          end.to change{subject.access_token}.to('new_access_token')
        end
      end
    end
  end
end
