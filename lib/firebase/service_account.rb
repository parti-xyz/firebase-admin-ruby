module Firebase
  class ServiceAccount
    attr_accessor :service_account

    def initialize(service_account_content)
      @service_account = service_account_content
    end

    def private_key
      @service_account["private_key"]
    end

    def client_email
      @service_account["client_email"]
    end

    def token_uri
      @service_account["token_uri"]
    end
  end
end
