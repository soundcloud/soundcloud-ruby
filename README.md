# Soundcloud API Wrapper
## Declientription
The Soundcloud gem is a thin wrapper for the Soundcloud API based of the httparty gem.
It is providing simple methods to handle authorization and to execute HTTP calls.

## Requirements
* httmultiparty
* httparty
* crack
* multipart-upload
* hashie

## Installation
    gem install soundcloud

## Examples
#### Print links of the 10 hottest tracks
    # register a client with YOUR_CLIENT_ID as client_id_
    client = Soundcloud.new(:client_id => YOUR_CLIENT_ID)
    # get 10 hottest tracks
    tracks = client.get('/tracks', :limit => 10, :order => 'hotness')
    # print each link
    tracks.each do |track|
      puts track.permalink_url
    end
  
#### OAuth2 user credentials flow and print the username of the authenticated user
    # register a new client, which will exchange the username, password for an access_token
    # NOTE: the SoundCloud API Docs advices to not use the user credentials flow in a web app.
    # In any case never store the password of a user.
    client = Soundcloud.new({
      :client_id      => YOUR_CLIENT_ID,
      :client_secret  => YOUR_CLIENT_SECRET,
      :username       => 'some@email.com',
      :password       => 'userpass'
    })
    
    # print logged in username
    puts client.get('/me').username

#### OAuth2 authorization code flow
    client = Soundcloud.new({
      :client_id      => YOUR_CLIENT_ID,
      :client_secret  => YOUR_CLIENT_SECRET,
    })
    
    client.authorize_url(:redirect_uri => REDIRECT_URI)
    # => "https://soundcloud.com/connect?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=http://host/redirect"
    client.exchange_token(:redirect_uri => uri, :code => 'CODE')

#### OAuth2 refresh token flow, upload a track and print its link
    # register a new client which will exchange an existing refresh_token for an access_token
    client = Soundcloud.new({
      :client_id      => YOUR_CLIENT_ID,
      :client_secret  => YOUR_CLIENT_SECRET,
      :refresh_token  => SOME_REFRESH_TOKEN
    })
    
    # upload a new track with track.mp3 as audio and image.jpg as artwork
    track = client.post('/tracks', :track => {
      :title        => 'a new track',
      :asset_data   => File.new('audio.mp3')
    })
    
    # print new tracks link
    puts track.permalink_url

#### Resolve a track url and print its id
     # register the client
     client = Soundcloud.new(:client_id => YOUR_CLIENT_ID)
     
     # call the resolve endpoint with a track url
     track = client.get('/resolve', :url => "http://soundcloud.com/forss/flickermood")
     
     # print the track id
     puts track.id

#### Register a client for http://sandbox-soundcloud.com with an existing access_token and start following a user
    # register a client for http://sandbox-soundcloud.com with existing access_token
    client = Soundcloud.new(:site => 'sandbox-soundcloud.com', :access_token => SOME_ACCESS_TOKEN)
    
    # create a new following
    user_id_to_follow = 123
    client.put("/me/followings/#{user_id_to_follow}")

## Interface
#### Soundcloud.new(options={})
Stores the passed options and call exchange_token in case options are passed that allow an exchange of tokens.

#### Soundcloud#exchange_token(options={})
Stores the passed options and try to exchange tokens if no access_token is present and:
- refresh_token, client_id and client_secret is present.
- client_id, client_secret, username, password is present
- client_id, client_secret, redirect_uri, code is present

#### Soundcloud#authorize_url(options={})
Stores the passed options and return an authorize url.
The client_id and redirect_uri options need to present to generate the authorize url.

#### Soundcloud#get, Soundcloud#post, Soundcloud#put, Soundcloud#delete, Soundcloud#head
These methods expose all available HTTP methods. They all share the signature (path_or_uri, query={}, options={}).
The query hash will be merged with the options hash and passed to httparty. Depending on if the client is authorized it will either add the client_id or the access_token as a query parameter.
In case an access_token is expired and a refresh_token, client_id and client_secret is present it will try to refresh the access_token and retry the call.
The response is either a Hashie::Mash or an array of Hashie::Mashs. The mashs expose all resource attributes as methods and the original response through #response.

#### Soundcloud#client_id, client_secret, access_token, refresh_token, use_ssl?
These methods are accessors for the stored options.

### Soundcloud#on_exchange_token
A Proc passed to on_exchange_token will be called each time a token was successfully exchanged or refreshed

### Soundcloud#expires_at
Returns a date based on the expires_in attribute returned from a token exchange.

### Soundcloud#expired?
Will return true or false depending on if expires_at is in the past.

#### Error Handling
In case a request was not successful a Soundcloud::ResponseError will be raise.
The original HTTParty response is available through Soundcloud::ResponseError#response.
