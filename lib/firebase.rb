require 'firebase/response'
require 'firebase/server_value'
require 'firebase/service_account'
require 'firebase/token_generator'

require 'httpclient'
require 'json'
require 'uri'

module Firebase
  class Client
    attr_accessor :access_token, :request

    def initialize(base_uri, service_account_file_path)
      if base_uri !~ URI::regexp(%w(https))
        raise ArgumentError.new('base_uri must be a valid https uri')
      end
      base_uri += '/' unless base_uri.end_with?('/')
      @request = HTTPClient.new({
        :base_url => base_uri,
        :default_header => {
          'Content-Type' => 'application/json'
        }
      })

      service_account_content = JSON.parse(File.read(service_account_file_path))
      @service_account = Firebase::ServiceAccount.new(service_account_content)
    end

    # Writes and returns the data
    #   Firebase.set('users/info', { 'name' => 'Oscar' }) => { 'name' => 'Oscar' }
    def set(path, data, query={})
      process :put, path, data, query
    end

    # Returns the data at path
    def get(path, query={})
      process :get, path, nil, query
    end

    # Writes the data, returns the key name of the data added
    #   Firebase.push('users', { 'age' => 18}) => {"name":"-INOQPH-aV_psbk3ZXEX"}
    def push(path, data, query={})
      process :post, path, data, query
    end

    # Deletes the data at path and returs true
    def delete(path, query={})
      process :delete, path, nil, query
    end

    # Write the data at path but does not delete ommited children. Returns the data
    #   Firebase.update('users/info', { 'name' => 'Oscar' }) => { 'name' => 'Oscar' }
    def update(path, data, query={})
      process :patch, path, data, query
    end

    def custom_token(uid, claims={})
      Firebase::TokenGenerator.new(@service_account).request_custom_token(uid, claims)
    end

    def access_token
      @access_token ||= Firebase::TokenGenerator.new(@service_account).request_access_token
    end

    private

    def process(verb, path, data=nil, query={})
      Firebase::Response.new @request.request(verb, "#{path}.json", {
        :body             => (data && data.to_json),
        :query            => { :access_token => access_token }.merge(query),
        :follow_redirect  => true
      })
    end
  end
end
