# Soundcloud API Wrapper
## Description
This is a thin wrapper around the Soundcloud API based of httparty.
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
#### print links of the 10 hottest tracks
    # register a client with YOUR_CLIENT_ID as client_id_
    client = Soundcloud.new(:client_id => 'YOUR_CLIENT_ID')
    # get 10 hottest tracks
    tracks = client.get('/tracks', :limit => 10, :order => 'hotness')
    # print each link
    tracks.each do |track|
      puts track.permalink_url
    end
  
#### Do the OAuth2 user credentials flow and print the username of the authenticated user
    # register a new client, which will exchange the username, password for an access_token
    client = Soundcloud.new({
      :client_id      => 'YOUR_CLIENT_ID',
      :client_secret  => 'YOUR_CLIENT_SECRET',
      :username       => 'some@email.com',
      :password       => 'userpass'
    })
    
    # print logged in username
    puts client.get('/me').username
    
#### Do the OAuth2 authorization code flow
    sc = Soundcloud.new({
      :client_id      => 'YOUR_CLIENT_ID',
      :client_secret  => 'YOUR_CLIENT_SECRET',
    })
    
    sc.authorize_url(:redirect_uri => uri)
    # => "https://soundcloud.com/connect?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=http://host/redirect"
    sc.exchange_code(:redirect_uri => uri, :code => 'CODE')

#### Do the OAuth2 refresh token flow, upload a track and print its link
    # register a new client which will exchange an existing refresh_token for an access_token
    client = Soundcloud.new({
      :client_id      => 'YOUR_CLIENT_ID',
      :client_secret  => 'YOUR_CLIENT_SECRET',
      :refresh_token  => 'SOME_REFRESH_TOKEN'
    })
    
    # upload a new track with track.mp3 as audio and image.jpg as artwork
    track = client.post('/tracks', {
      :title        => 'a new track',
      :asset_data   => File.new('track.mp3'),
      :artwork_data => File.new('image.jpg')
    })
    
    # print new tracks link
    puts track.permalink_url

#### Resolve a track url and print its id
     # register the client
     client = Soundcloud.new(:client_id      => 'YOUR_CLIENT_ID')
     
     # call the resolve endpoint with a track url
     track = client.get('/resolve', :url => "http://soundcloud.com/forss/flickermood")
     
     # print the track id
     puts track.id

#### Register a client for http://sandbox-soundcloud.com with an existing access_token and start following a user
    # register a client for http://sandbox-soundcloud.com with existing access_token
    client = Soundcloud.new(:site => 'http://sandbox-soundcloud.com', :access_token => 'SOME_ACCESS_TOKEN')
    
    # create a new following
    user_id_to_follow = 123
    client.put("/me/followings/#{user_id_to_follow}")

## Details
#### Soundcloud.new(options={})
Will store the passed options and call exchange_token in case options are passed that allow an exchange of tokens.

#### Soundcloud#exchange_token(options={})
Will store the passed options and try to exchange tokens if no access_token is present and:
- refresh_token, client_id and client_secret is present.
- client_id, client_secret, username, password is present
- client_id, client_secret, redirect_uri, code is present

#### Soundcloud#authorize_url(options={})
Will store the passed options and return an authorize url.
The client_id and redirect_uri options need to present to generate the authorize url.

#### Soundcloud#get, Soundcloud#post, Soundcloud#put, Soundcloud#delete, Soundcloud#head
All available HTTP methods are exposed through these methods. They all share the signature (path_or_uri, query={}, options={}).
The query hash will be merged with the options hash and passed to httparty. Depending on if the client is authorized it will either add the client_id or the access_token as a query parameter.
In case an access_token is expired and a refresh_token is present it will try to refresh the access_token and retry the call.
The response is either a Hashie::Mash or an array of Hashie::Mashs. The mashs expose all resource attributes as methods and the original response through #response.

#### Soundcloud#client_id, client_secret, access_token, refresh_token, use_ssl?
These are accessor to the stored options.

#### Error Handling
In case of an unsuccessful request a Soundcloud::ResponseError will be raise.
The original HTTParty response is available through Soundcloud::ResponseError#response.