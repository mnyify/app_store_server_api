# frozen_string_literal: true

require "openssl"
require "jwt"

module AppStoreServerApi
  module Utils
    module Decoder
      module_function

      def decode_jws! jws
        payload, = JWT.decode(jws, nil, true, algorithm: "ES256") do |header|
          certs = header["x5c"].map { |c| OpenSSL::X509::Certificate.new Base64.urlsafe_decode64(c) }
          apple_root_cas.include? certs.last or raise JWT::DecodeError, "Missing root certificate"
          certs.each_cons(2).all? { |a, b| a.verify(b.public_key) } or raise JWT::DecodeError, "Broken trust chain"
          certs[0].public_key
        end
        payload
      end

      def decode_transaction(signed_transaction:)
        decode_jws! signed_transaction
      end

      def decode_transactions(signed_transactions:)
        signed_transactions.map do |signed_transaction|
          decode_transaction signed_transaction: signed_transaction
        end
      end

      def apple_root_cas
        Dir.glob(File.join(__dir__, "certs", "*.cer")).map do |filename|
          OpenSSL::X509::Certificate.new File.read(filename)
        end
      end
    end
  end
end
