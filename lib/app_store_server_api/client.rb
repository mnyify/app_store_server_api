require "jwt"

require "net/http"
require "uri"
require "json"
require "openssl"

module AppStoreServerApi
  class Client
    def initialize(
      private_key:, # p8 key
      key_id:,      # Your private key ID from App Store Connect (Ex: 2X9R4HXF34)
      issuer_id:,   # Your issuer ID from the Keys page in App Store Connect
      bundle_id:,   # Your app’s bundle ID (Ex: “com.example.testbundleid”)
      environment: :production
    )

      @private_key = private_key
      @key_id = key_id
      @issuer_id = issuer_id
      @bundle_id = bundle_id
      @base_url = app_store_base_url environment
    end

    def get_transaction_history(transaction_id, params: nil)
      request_uri("#{@base_url}/inApps/v1/history/#{transaction_id}", params: params)
    end

    def get_transaction_info(transaction_id, params: nil)
      request_uri("#{@base_url}/inApps/v1/transactions/#{transaction_id}", params: params)
    end

    # status
    #
    # 1, The auto-renewable subscription is active.
    # 2, The auto-renewable subscription is expired.
    # 3, The auto-renewable subscription is in a billing retry period.
    # 4, The auto-renewable subscription is in a Billing Grace Period.
    # 5, The auto-renewable subscription is revoked. The App Store refunded the transaction or revoked it from Family Sharing
    def get_all_subscription_statuses(transaction_id, params: nil)
      request_uri("#{@base_url}/inApps/v1/subscriptions/#{transaction_id}", params: params)
    end

    def request_a_test_notification
      request_uri "#{@base_url}/inApps/v1/notifications/test", http_method: :post
    end

    private

    def request_uri(uri, http_method: :get, headers: nil, params: nil, timeout: 5)
      uri = URI(uri)
      uri.query = URI.encode_www_form(params) if params && http_method == :get

      # Create a new Net::HTTP object and set timeout
      http = Net::HTTP.new(uri.host, 443)

      http.open_timeout = timeout
      http.read_timeout = timeout

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      # Make the HTTP request
      begin
        request = (http_method == :get) ? Net::HTTP::Get.new(uri.request_uri) : Net::HTTP::Post.new(uri.request_uri)

        request.initialize_http_header headers || request_headers

        if http_method == :post
          request.body = params.to_json
        end

        response = http.request request

        # Raise an error if the response is not successful
        response.value

        # Parse response body to JSON
        JSON.parse response.body
      rescue Net::OpenTimeout
        raise "Timeout while opening the connection"
      rescue Net::ReadTimeout
        raise "Timeout while reading data"
      rescue => e
        raise "Error: #{e.message}"
      end
    end

    def bearer_token
      if @bearer_token
        begin
          JWT.decode @bearer_token, OpenSSL::PKey::EC.new(@private_key), true, {algorithm: "ES256"}
          return @bearer_token
        rescue JWT::ExpiredSignature
        end
      end

      @bearer_token = generate_bearer_token(
        key_id: @key_id,
        issuer_id: @issuer_id,
        private_key: @private_key,
        bundle_id: @bundle_id
      )
    end

    def request_headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{bearer_token}"
      }
    end

    def generate_bearer_token(
      key_id:,
      issuer_id:,
      bundle_id:,
      private_key:,
      audience: "appstoreconnect-v1", # appstoreconnect-v1,
      issued_at: Time.now.to_i, # The time at which you issue the token, in UNIX time, in seconds (Ex: 1623085200)
      expired_in: 3600,
      alg: "ES256",
      typ: "JWT"
    )

      payload = {
        iss: issuer_id,
        iat: issued_at,
        exp: expired_in + issued_at,
        aud: audience,
        bid: bundle_id
      }

      JWT.encode payload, OpenSSL::PKey::EC.new(private_key), alg, {typ: typ, kid: key_id}
    end

    def app_store_base_url environment
      if environment == :production
        "https://api.storekit.itunes.apple.com"
      else
        "https://api.storekit-sandbox.itunes.apple.com"
      end
    end
  end
end
