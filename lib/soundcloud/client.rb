require 'soundcloud/version'

module SoundCloud
  class Client
    include HTTMultiParty
    USER_AGENT            = "SoundCloud Ruby Wrapper #{SoundCloud::VERSION}"
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
      if access_token.nil? && (options_for_refresh_flow_present? || options_for_credentials_flow_present? || options_for_code_flow_present?)
        exchange_token
      end
      raise ArgumentError, "At least a client_id or an access_token must be present" if client_id.nil? && access_token.nil?
    end

    def get(path, query={}, options={})
      handle_response {
        self.class.get(*construct_query_arguments(path, options.merge(:query => query)))
      }
    end

    def post(path, body={},  options={})
      handle_response {
        self.class.post(*construct_query_arguments(path, options.merge(:body => body), :body))
      }
    end

    def put(path, body={},  options={})
      handle_response {
        self.class.put(*construct_query_arguments(path, options.merge(:body => body), :body))
      }
    end

    def delete(path, query={}, options={})
      handle_response {
        self.class.delete(*construct_query_arguments(path, options.merge(:query => query)))
      }
    end

    def head(path, query={}, options={})
      handle_response {
        self.class.head(*construct_query_arguments(path, options.merge(:query => query)))
      }
    end

    # accessors for options
    def client_id
      @options[:client_id]
    end

    def client_secret
      @options[:client_secret]
    end

    def access_token
      @options[:access_token]
    end

    def refresh_token
      @options[:refresh_token]
    end

    def redirect_uri
      @options[:redirect_uri]
    end

    def expires_at
      @options[:expires_at]
    end

    def expired?
      (expires_at.nil? || expires_at < Time.now)
    end

    def use_ssl?
      !!(@options[:use_ssl?] || access_token)
    end

    def site
      @options[:site]
    end
    alias host site

    def api_host
      [API_SUBHOST, host].join('.')
    end

    def authorize_url(options={})
      additional_params = [:display, :state, :scope].map do |param_name|
        value = options.delete(param_name)
        "#{param_name}=#{CGI.escape value}" unless value.nil?
      end.compact.join("&")
      store_options(options)
      "https://#{host}#{AUTHORIZE_PATH}?response_type=code_and_token&client_id=#{client_id}&redirect_uri=#{URI.escape(redirect_uri)}&#{additional_params}"
    end

    def exchange_token(options={})
      store_options(options)
      raise ArgumentError, 'client_id and client_secret is required to retrieve an access_token' if client_id.nil? || client_secret.nil?
      client_params = {:client_id => client_id, :client_secret => client_secret}
      params = if options_for_refresh_flow_present?
        {
          :grant_type => 'refresh_token',
          :refresh_token => refresh_token,
        }
      elsif options_for_credentials_flow_present?
        {
          :grant_type => 'password',
          :username => @options[:username],
          :password => @options[:password],
        }
      elsif options_for_code_flow_present?
        {
          :grant_type => 'authorization_code',
          :redirect_uri => @options[:redirect_uri],
          :code => @options[:code],
        }
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
          raise ResponseError.new(response)
        end
      elsif response_is_a?(response, Hash)
        HashResponseWrapper.new(response)
      elsif response_is_a?(response, Array)
        ArrayResponseWrapper.new(response)
      elsif response && response.success?
        response
      end
    end

    def options_for_refresh_flow_present?
      !!@options[:refresh_token]
    end

    def options_for_credentials_flow_present?
      !!(@options[:username] && @options[:password])
    end

    def options_for_code_flow_present?
      !!(@options[:code] && @options[:redirect_uri])
    end

    def store_options(options={})
      @options ||= DEFAULT_OPTIONS.dup
      @options.merge!(options)
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

    def response_is_a?(response, type)
      response.is_a?(type) || (response.respond_to?(:parsed_response) && response.parsed_response.is_a?(type))
    end

  end
end
