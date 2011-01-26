# Soundcloud API Wrapper
## Description
This is a thin wrapper around the Soundcloud API based of httparty.
It is providing simple methods to handle authorization and to execute http methods.

## Requirements
* httmultiparty
* httparty
* crack
* multipart-upload
* mash

## Installation
    gem install soundcloud

## Examples
#### get links to the 10 hottest tracks
    # register a client with YOUR_APP_KEY as client_id_
    client = Soundcloud.new(:client_id => 'YOUR_APP_KEY')
    # get 10 hottest tracks
    tracks = client.get('/tracks', :query => {:limit => 10, :order => 'hotness'})
    # print each link
    tracks.each do |track|
      puts track.permalink_url
    end
  
#### OAuth2 user credentials flow, print username
    # register a new client, which will exchange the username, password for an access_token
    client = Soundcloud.new({
      :client_id      => 'YOUR_APP_KEY',
      :client_secret  => 'YOUR_APP_SECRET',
      :username       => 'some@email.com',
      :password       => 'userpass'
    })
    
    # print logged in username
    puts client.get('/me').username
    
#### OAuth2 authorization code flow
    sc = Soundcloud.new({
      :client_id      => 'YOUR_APP_KEY',
      :client_secret  => 'YOUR_APP_SECRET',
    })
    
    sc.authorize_url(:redirect_uri => uri)
    # => "https://soundcloud.com/connect?client_id=YOUR_APP_KEY&response_type=code&redirect_uri=http://host/redirect"
    sc.exchange_code(:redirect_uri => uri, :code => 'CODE')

#### OAuth2 refresh token flow, upload a track
    # register a new client which will exchange an existing refresh_token for an access_token
    client = Soundcloud.new({
      :client_id      => 'YOUR_APP_KEY',
      :client_secret  => 'YOUR_APP_SECRET',
      :refresh_token  => 'SOME_REFRESH_TOKEN'
    })
    
    # upload a new track with track.mp3 as audio and image.jpg as artwork
    track = client.post('/tracks', :query => {
      :title        => 'a new track',
      :asset_data   => File.new('track.mp3'),
      :artwork_data => File.new('image.jpg')
    })
    
    # print new tracks link
    puts track.permalink_url

#### Resolve a track url and print its id
     # register the client
     client = Soundcloud.new(:client_id      => 'YOUR_APP_KEY')
     
     # call the resolve endpoint with a track url
     track = client.get('/resolve', :query => {:url => "http://soundcloud.com/forss/flickermood"})
     
     # print the track id
     puts track.id

#### Register a client for http://sandbox-soundcloud.com with existing access_token and start following a user_
    # register a client for http://sandbox-soundcloud.com with existing access_token
    client = Soundcloud.new(:site => 'http://sandbox-soundcloud.com', :access_token => 'SOME_ACCESS_TOKEN')
    
    # create a new following
    user_id_to_follow = 123
    client.put("/me/followings/#{user_id_to_follow}")

## Details
#### Soundcloud.new(options={})
Will store the passed options and call exchange_token in case options are passed that allow an exchange of tokens.

#### Soundcloud#exchange_token(options={})
Will store the passed options and try to exchange tokens.
params = if options_for_refresh_flow_present?
  {:grant_type => 'refresh_token',      :refresh_token => refresh_token}
elsif options_for_credentials_flow_present?
  {:grant_type => 'password',           :username      => @options[:username],     :password => @options[:password]}
elsif options_for_code_flow_present?
  {:grant_type => 'authorization_code', :redirect_uri  => @options[:redirect_uri], :code => @options[:code]}
  
#### Soundcloud#authorize_url(options={})
Will store the passed options and return an authorize url.
The client_id and redirect_uri options need to present to generate the authorize url.

#### Soundcloud#get, Soundcloud#post, Soundcloud#put, Soundcloud#delete, Soundcloud#head
All available HTTP methods are exposed through these methods. They all share the signature (path_or_uri, options).
The query can be passed through the options hash. Depending if the client is authorized it will either add the client_id or the access_token as a query parameter.
In case an access_token is expired and a refresh_token is present it will try to refresh the access_token and retry the call.
The response is either a Mash or an array of Mashs. The mashs expose all resource attributes as methods and the original response through #response.

#### Soundcloud#client_id, client_secret, access_token, refresh_token, use_ssl?
These are accessor to the stored options

#### Error Handling
In case of an unsuccessful request a Soundcloud::ResponseError will be raise.
The original response is available through Soundcloud::ResponseError#response.