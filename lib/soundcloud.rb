gem 'httmultiparty'
gem 'mash'
require 'httmultiparty'
require 'hashie'
require 'uri'

class Soundcloud
  class ResponseError < HTTParty::ResponseError; end
  include HTTMultiParty
  headers 'Accept' => 'application/json'
  
  # TODO fix when api is ready for client_id
  CLIENT_ID_PARAM_NAME  = :consumer_key
  API_SUBHOST           = 'api'
  AUTHORIZE_PATH        = '/connect'
  TOKEN_PATH            = '/oauth2/token'
  DEFAULT_OPTIONS       = {
    :site => 'soundcloud.com'
  }


  def initialize(options={})
    store_options(options)
    if access_token.nil? && (options_for_refresh_flow_present? ||
                             options_for_credentials_flow_present? || options_for_code_flow_present?)
      exchange_token
    end

    raise ArgumentError, "At least a client_id or an access_token must be present" if client_id.nil? && access_token.nil?
  end

  # the exposed http methods
  def get   (path, options={}); handle_response { self.class.get    *construct_query_arguments(path, options) } end
  def post  (path, options={}); handle_response { self.class.post   *construct_query_arguments(path, options) } end
  def put   (path, options={}); handle_response { self.class.put    *construct_query_arguments(path, options) } end
  def delete(path, options={}); handle_response { self.class.delete *construct_query_arguments(path, options) } end
  def head  (path, options={}); handle_response { self.class.head   *construct_query_arguments(path, options) } end
  
  # accessors for options
  def client_id;      @options[:client_id];     end
  def client_secret;  @options[:client_secret]; end
  def access_token;   @options[:access_token];  end
  def refresh_token;  @options[:refresh_token]; end
  def use_ssl?; 
    !! @options[:use_ssl?] || access_token
  end

  def site; @options[:site]; end
  
  def host; site; end
  def api_host; [API_SUBHOST, host].join('.'); end

  def authorize_url(options={})
    store_options(options)
    "https://#{host}#{AUTHORIZE_PATH}?response_type=code&client_id=#{client_id}&redirect_uri=#{URI.escape redirect_uri}"
  end
  
  def exchange_token(options={})
    store_options(options)
    raise ArgumentError, 'client_id and client_secret is required to retrieve an access_token' if client_id.nil? || client_secret.nil?
    client_params = {:client_id => client_id, :client_secret => client_secret}
    params = if options_for_refresh_flow_present?
      {:grant_type => 'refresh_token',      :refresh_token => refresh_token}
    elsif options_for_credentials_flow_present?
      {:grant_type => 'password',           :username      => @options[:username],     :password => @options[:password]}
    elsif options_for_code_flow_present?
      {:grant_type => 'authorization_code', :redirect_uri  => @options[:redirect_uri], :code => @options[:code]}
    end
    params.merge!(client_params)
    response = self.class.post("https://#{api_host}#{TOKEN_PATH}", :query => params)
    @options.merge!(:access_token => response['access_token'], :refresh_token => response['refresh_token'])
    response
  end
  
private
  def handle_response(refreshing_enabled=true, &block)
    response = block.call
    if response && !response.success?
      if response.code == 401 && response["error"] == "invalid_grant" && refreshing_enabled
        exchange_token
        # TODO it should return the original
        handle_response(false, &block)
      else
        raise ResponseError.new(response), "HTTP Status #{response.code}"
      end
    elsif response.is_a? Hash
      HashResponseWrapper.new(response)
    elsif response.is_a? Array
      ArrayResponseWrapper.new(response)
    end
  end

  def options_for_refresh_flow_present?;     !! @options[:refresh_token]; end
  def options_for_credentials_flow_present?; !! @options[:username] && @options[:password]; end
  def options_for_code_flow_present?;        !! @options[:code] && @options[:redirect_uri]; end

  def store_options(options={})
    @options ||= DEFAULT_OPTIONS.dup
    @options.merge! options
  end
  
  def construct_query_arguments(path, options={})
    scheme = use_ssl? ? 'https' : 'http'
    options = options.dup
    options[:query] ||= {}

    if access_token
      options[:query][:oauth_token] = access_token
    else
      options[:query][CLIENT_ID_PARAM_NAME] = client_id
    end
    [
      "#{scheme}://#{api_host}#{path}",
      options
    ]
  end
end

require 'soundcloud/array_response_wrapper'
require 'soundcloud/hash_response_wrapper'

