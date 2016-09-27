# SoundCloud API Wrapper

[![Build Status](https://travis-ci.org/soundcloud/soundcloud-ruby.png?branch=master)](https://travis-ci.org/soundcloud/soundcloud-ruby)

## Description
The official SoundCloud API wrapper. It provides simple methods to handle
authorization and to execute HTTP calls.

## Installation
```sh
gem install soundcloud
```

## Examples

The following examples are for the [latest gem version](https://rubygems.org/gems/soundcloud).

```ruby
SoundCloud::VERSION
# => "0.3.4"
```

#### Print links of the 10 most recent tracks
```ruby
# register a client with YOUR_CLIENT_ID as client_id_
client = SoundCloud.new(:client_id => YOUR_CLIENT_ID)
# get newest tracks
tracks = client.get('/tracks', :limit => 10)
# print each link
tracks.each do |track|
  puts track.permalink_url
end
```

#### OAuth2 user credentials flow and print the username of the authenticated user
```ruby
# register a new client, which will exchange the username, password for an access_token
# NOTE: the SoundCloud API Docs advise not to use the user credentials flow in a web app.
# In any case, never store the password of a user.
client = SoundCloud.new({
  :client_id     => YOUR_CLIENT_ID,
  :client_secret => YOUR_CLIENT_SECRET,
  :username      => 'some@email.com',
  :password      => 'userpass'
})

# print logged in username
puts client.get('/me').username
```

#### OAuth2 authorization code flow
```ruby
client = SoundCloud.new({
  :client_id     => YOUR_CLIENT_ID,
  :client_secret => YOUR_CLIENT_SECRET,
  :redirect_uri  => YOUR_REDIRECT_URI,
})

redirect client.authorize_url()
# the user should be redirected to "https://soundcloud.com/connect?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=YOUR_REDIRECT_URI"
# after granting access he will be redirected back to YOUR_REDIRECT_URI
# in your respective handler you can build an exchange token from the transmitted code
client.exchange_token(:code => params[:code])
```

#### OAuth2 refresh token flow, upload a track and print its link
```ruby
# register a new client which will exchange an existing refresh_token for an access_token
client = SoundCloud.new({
  :client_id     => YOUR_CLIENT_ID,
  :client_secret => YOUR_CLIENT_SECRET,
  :refresh_token => SOME_REFRESH_TOKEN
})

# upload a new track with audio.mp3 as audio and image.jpg as artwork
track = client.post('/tracks', :track => {
  :title      => 'a new track',
  :asset_data => File.new('audio.mp3')
})

# print new tracks link
puts track.permalink_url
```

#### Resolve a track url and print its id
```ruby
# register the client
client = SoundCloud.new(:client_id => YOUR_CLIENT_ID)

# call the resolve endpoint with a track url
track = client.get('/resolve', :url => "http://soundcloud.com/forss/flickermood")

# print the track id
puts track.id
```

### Initializing a client with an access token and updating the users profile description
```ruby
# initializing a client with an access token
client = SoundCloud.new(:access_token => SOME_ACCESS_TOKEN)

# updating the users profile description
client.put("/me", :user => {:description => "a new description"})
```

### Add a track to a playlist / set
```ruby
client = SoundCloud.new(:access_token => "A_VALID_TOKEN")

# get my last playlist
playlist = client.get("/me/playlists").first

# get ids of contained tracks
track_ids = playlist.tracks.map(&:id) # => [22448500, 21928809]

# adding a new track 21778201
track_ids << 21778201 # => [22448500, 21928809, 21778201]

# map array of ids to array of track objects:
tracks = track_ids.map{|id| {:id => id}} # => [{:id=>22448500}, {:id=>21928809}, {:id=>21778201}]

# send update/put request to playlist
playlist = client.put(playlist.uri, :playlist => {
  :tracks => tracks
})

# print the list of track ids of the updated playlist:
p playlist.tracks.map(&:id)
```

## Interface
#### SoundCloud.new(options={})
Stores the passed options and call exchange_token in case options are passed
that allow an exchange of tokens.

#### SoundCloud#exchange_token(options={})
Stores the passed options and try to exchange tokens if no access_token is
present and:

* `refresh_token`, `client_id` and `client_secret` is present.
* `client_id`, `client_secret`, `username`, and `password` is present
* `client_id`, `client_secret`, `redirect_uri`, and `code` is present

#### SoundCloud#authorize_url(options={})
Stores the passed options except for `state` and `display` and return an
authorize url. The `client_id` and `redirect_uri` options need to present to
generate the authorize url. The `state` and `display` options can be used to
set the parameters accordingly in the authorize url.

#### SoundCloud#get, SoundCloud#post, SoundCloud#put, SoundCloud#delete, SoundCloud#head
These methods expose all available HTTP methods. They all share the signature
`(path_or_uri, query={}, options={})`. The query hash will be merged with the
options hash and passed to httparty. Depending on if the client is authorized
it will either add the client_id or the access_token as a query parameter. In
case an access_token is expired and a `refresh_token`, `client_id` and
`client_secret` is present it will try to refresh the `access_token` and retry
the call. The response is either a Hashie::Mash or an array of Hashie::Mashes.
The mashes expose all resource attributes as methods and the original response
through `HashResponseWrapper#response`.

#### SoundCloud#client_id, client_secret, access_token, refresh_token, use_ssl?
These methods are accessors for the stored options.

#### SoundCloud#on_exchange_token
A Proc passed to on_exchange_token will be called each time a token was
successfully exchanged or refreshed

#### SoundCloud#expires_at
Returns a date based on the `expires_in` attribute returned from a token
exchange.

#### SoundCloud#expired?
Will return true or false depending on if `expires_at` is in the past.

#### Error Handling
In case a request was not successful a SoundCloud::ResponseError will be
raised. The original HTTParty response is available through
`SoundCloud::ResponseError#response`.

## Documentation

For more code examples, please visit the [SoundCloud API Documentation](http://developers.soundcloud.com/docs).
