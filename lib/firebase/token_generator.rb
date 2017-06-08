module Firebase
  class TokenGenerator
    attr_accessor :service_account

    def initialize(service_account)
      @service_account = service_account
    end

    def request_custom_token(uid, claims)
      generate_custom_token(uid, claims)
    end

    def request_access_token
      generate_access_token
    end

    private

    def generate_custom_token(uid, claims)
      payload = custom_token_payload(uid, claims)
      private_key = OpenSSL::PKey::RSA.new(@service_account.private_key)
      JWT.encode(payload, private_key, "RS256")
    end

    # https://firebase.google.com/docs/auth/admin/create-custom-tokens?hl=ko
    def custom_token_payload(uid, claims)
      service_account_email = @service_account.client_email
      now_seconds = Time.now.to_i
      {
        :iss => service_account_email,
        :sub => service_account_email,
        :aud => "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
        :iat => now_seconds,
        :exp => now_seconds + 1.hour.to_i, # Maximum expiration time is one hour
        :uid => uid,
        :claims => claims
      }
    end

    # The tokens generated here are the ones we can use from the server to talk to firebase
    # this is the recommended way from google to authenticate to Firebase
    # Reference https://developers.google.com/identity/protocols/OAuth2ServiceAccount
    def generate_access_token
      payload = access_token_payload
      private_key = OpenSSL::PKey::RSA.new(@service_account.private_key)
      request_token = JWT.encode(payload, private_key, "RS256")

      response = RestClient.post @service_account.token_uri, { :grant_type => "urn:ietf:params:oauth:grant-type:jwt-bearer", :assertion => request_token }
      JSON.parse(response)['access_token']
    end

    def access_token_payload
      service_account_email = @service_account.client_email
      token_uri = @service_account.token_uri
      now_seconds = Time.now.to_i
      {
        :iss => service_account_email,
        :aud => token_uri,
        :scope => "https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email",
        :iat => now_seconds,
        :exp => now_seconds + 1.hour.to_i, # Maximum expiration time is one hour
      }
    end
  end
end
