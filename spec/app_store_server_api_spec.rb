# frozen_string_literal: true

RSpec.describe AppStoreServerApi do
  let(:client) do
    AppStoreServerApi::Client.new(
      private_key: File.read(ENV["private_key"]),
      key_id: ENV["key_id"],
      issuer_id: ENV["issuer_id"],
      bundle_id: ENV["bundle_id"],
      environment: :sandbox
    )
  end

  describe "API" do
    it "request_a_test_notification API" do
      data = client.request_a_test_notification
      expect(data["testNotificationToken"]).not_to be_nil
    end

    it "get_all_subscription_statuses API" do
      transaction_id = ENV["transaction_id"]

      response = client.get_all_subscription_statuses transaction_id

      signed = response["data"].first["lastTransactions"].first["signedTransactionInfo"]
      transaction = AppStoreServerApi::Utils::Decoder.decode_transaction signed_transaction: signed

      expect(
        transaction["originalTransactionId"]
      ).to eq transaction_id
    end

    it "get_transaction_history API" do
      transaction_id = ENV["transaction_id"]

      data = client.get_transaction_history(transaction_id,
        params: {
          sort: "DESCENDING"
        })

      transactions = AppStoreServerApi::Utils::Decoder.decode_transactions signed_transactions: data["signedTransactions"]
      expect(transactions.sample["originalTransactionId"]).to eq transaction_id
    end
  end

  describe "utils" do
    it "apple_root_cas" do
      AppStoreServerApi::Utils::Decoder.apple_root_cas
    end
  end
end
