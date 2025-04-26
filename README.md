# app-store-server-api
A Ruby client for the [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi), offering:
- Transaction history, transaction info, and subscription status endpoints
- Test notification and notification history endpoints
- Automatic ES256 JWT authentication with token refresh
- Helpers for decoding and verifying JWS payloads
- Built-in trust chain validation against Apple Root CAs

[![Gem Version](https://badge.fury.io/rb/app_store_server_api.svg)](https://badge.fury.io/rb/app_store_server_api)

## Features
* Transaction history, transaction info, and subscription status endpoints
* Test notification and notification history endpoints
* Automatic ES256 JWT authentication with token refresh
* Helpers for decoding and verifying JWS payloads
* Built-in trust chain validation against Apple Root CAs

## Requirements
- Ruby 3.0 or higher

## Installation

### RubyGems
```bash
gem install app_store_server_api
```

### Bundler
Add to your `Gemfile`:
```ruby
gem 'app_store_server_api'
```
Run:
```bash
bundle install
```

## Usage

### Prerequisites
To get started, you must obtain the following:
- An [API key](https://developer.apple.com/documentation/appstoreserverapi/creating_api_keys_to_use_with_the_app_store_server_api)
- The ID of the key
- Your [issuer ID](https://developer.apple.com/documentation/appstoreserverapi/generating_tokens_for_api_requests)

### Configure

**In your Rails application, create a client configure**

```ruby
# my_app/config/app_store_server.yml
default: &default
  private_key: |
    -----BEGIN PRIVATE KEY-----
  key_id: S4AZ693A4A
  issuer_id: fd02853a-1290-4854-875e-918c86459b3e
  bundle_id: com.myapp.app
  environment: sandbox

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
```

**Load the configure**

```ruby
# my_app/config/application.rb

config.app_store_server = config_for :app_store_server
```

**Create a global client**

```ruby
# my_app/config/initializers/app_store_server_api.rb

AppStoreServerApiClient = AppStoreServerApi::Client.new(**Rails.configuration.app_store_server)
```

### API

**Get Transaction History**

```ruby
data = client.get_transaction_history(transaction_id,
  params: {
    sort: "DESCENDING"
  })

transactions = AppStoreServerApi::Utils::Decoder.decode_transactions signed_transactions: data["signedTransactions"]
```

**Get Transaction Info**

```ruby
client.get_transaction_info transaction_id
```

**Get All Subscription Statuses**
```ruby
response = client.get_all_subscription_statuses transaction_id

signed = response["data"].first["lastTransactions"].first["signedTransactionInfo"]

transaction = AppStoreServerApi::Utils::Decoder.decode_transaction signed_transaction: signed
```

**Request a Test Notification**

```ruby
client.request_a_test_notification
```


**Utils**

- AppStoreServerApi::Utils::Decoder.decode_transaction
- AppStoreServerApi::Utils::Decoder.decode_jws!


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AppStoreServerApi project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mnyify/app_store_server_api/blob/main/CODE_OF_CONDUCT.md).
