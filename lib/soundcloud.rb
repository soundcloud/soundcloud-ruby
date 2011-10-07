require 'httmultiparty'
require 'hashie'
require 'uri'
require 'soundcloud/version'

class Soundcloud
  class ResponseError < HTTParty::ResponseError
    def message
      error = response.parsed_response['error'] || response.parsed_response['errors']['error']
      "HTTP status: #{StatusCodes.interpret_status(response.code)} Error: #{error}"
    rescue
      "HTTP status: #{StatusCodes.interpret_status(response.code)}"
    end

    module StatusCodes
      STATUS_CODES = {
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",

        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-Authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        226 => "IM Used",

        300 => "Multiple Choices",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        305 => "Use Proxy",
        307 => "Temporary Redirect",

        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Request Entity Too Large",
        414 => "Request-URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Requested Range Not Satisfiable",
        417 => "Expectation Failed",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        426 => "Upgrade Required",

        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        507 => "Insufficient Storage",
        510 => "Not Extended"
      }

      def self.interpret_status(status)
        "#{status} #{STATUS_CODES[status.to_i]}".strip
      end
    end
  end
  
  class UnauthorizedResponseError < ResponseError; end
  USER_AGENT            = "SoundCloud Ruby Wrapper #{VERSION}"

  include HTTMultiParty
  CLIENT_ID_PARAM_NAME  = :client_id
  API_SUBHOST           = 'api'
  AUTHORIZE_PATH        = '/connect'
  TOKEN_PATH            = '/oauth2/token'
  DEFAULT_OPTIONS       = {
    :site              => 'soundcloud.com',
    :on_exchange_token => lambda {}
  }

  attr_accessor :options
  headers({"User-Agent" => USER_AGENT})

  def initialize(options={})
    store_options(options)
    if access_token.nil? && (options_for_refresh_flow_present? ||
                             options_for_credentials_flow_present? || options_for_code_flow_present?)
      exchange_token
    end

    raise ArgumentError, "At least a client_id or an access_token must be present" if client_id.nil? && access_token.nil?
  end

  def get   (path, query={}, options={}); handle_response { self.class.get     *construct_query_arguments(path, options.merge(:query => query)) } end
  def post  (path, body={},  options={}); handle_response { self.class.post    *construct_query_arguments(path, options.merge(:body  => body), :body) } end
  def put   (path, body={},  options={}); handle_response { self.class.put     *construct_query_arguments(path, options.merge(:body  => body), :body) } end
  def delete(path, query={}, options={}); handle_response { self.class.delete  *construct_query_arguments(path, options.merge(:query => query)) } end
  def head  (path, query={}, options={}); handle_response { self.class.head    *construct_query_arguments(path, options.merge(:query => query)) } end

  # accessors for options
  def client_id;      @options[:client_id];     end
  def client_secret;  @options[:client_secret]; end
  def access_token;   @options[:access_token];  end
  def refresh_token;  @options[:refresh_token]; end
  def redirect_uri;   @options[:redirect_uri];  end
  def expires_at;     @options[:expires_at];    end

  def expired?
    (expires_at.nil? || expires_at < Time.now)
  end

  def use_ssl?; 
    !! @options[:use_ssl?] || access_token
  end

  def site; @options[:site]; end
  
  def host; site; end
  def api_host; [API_SUBHOST, host].join('.'); end

  def authorize_url(options={})
    additional_params = [:display, :state, :scope].map do |param_name|
      value = options.delete(param_name)
      "#{param_name}=#{CGI.escape value}" unless value.nil?
    end.compact.join("&")

    store_options(options)
    "https://#{host}#{AUTHORIZE_PATH}?response_type=code_and_token&client_id=#{client_id}&redirect_uri=#{URI.escape redirect_uri}&#{additional_params}"
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
    response = handle_response(false) {
      self.class.post("https://#{api_host}#{TOKEN_PATH}", :query => params)
    }
    @options.merge!(:access_token => response.access_token, :refresh_token => response.refresh_token)
    @options[:expires_at] = Time.now + response.expires_in if response.expires_in
    @options[:on_exchange_token].call(*[(self if @options[:on_exchange_token].arity == 1)].compact)
    response
  end

  def on_exchange_token(&block)
    store_options(:on_exchange_token => block)
  end

private
  def handle_response(refreshing_enabled=true, &block)
    response = block.call
    if response && !response.success?
      if response.code == 401 && refreshing_enabled && options_for_refresh_flow_present?
        exchange_token
        # TODO it should return the original
        handle_response(false, &block)
      else
        #raise ResponseError.new(response), ResponseError.message(response)
        raise ResponseError.new(response)
        #raise ResponseError.from(response)
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
  

  def construct_query_arguments(path_or_uri, options={}, body_or_query=:query)
    uri = URI.parse(path_or_uri)
    path = uri.path
    
    scheme = use_ssl? ? 'https' : 'http'
    options = options.dup
    options[body_or_query] ||= {}
    options[body_or_query][:format] = "json"
    if access_token
      options[body_or_query][:oauth_token] = access_token
    else
      options[body_or_query][CLIENT_ID_PARAM_NAME] = client_id
    end
    [
      "#{scheme}://#{api_host}#{path}#{uri.query ? "?#{uri.query}" : ""}",
      options
    ]
  end
end

require 'soundcloud/array_response_wrapper'
require 'soundcloud/hash_response_wrapper'
