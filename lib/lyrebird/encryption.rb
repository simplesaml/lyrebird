# frozen_string_literal: true

module Lyrebird
  class Encryption
    def initialize(element, certificate)
      @element = element
      @certificate = certificate
      @aes_key = SecureRandom.random_bytes(32)
    end

    def encrypt
      Nokogiri::XML::Builder.new do |xml|
        xml["saml"].EncryptedAssertion("xmlns:saml" => SAML_ASSERTION_NS) do
          encrypted_data(xml)
        end
      end.doc.root
    end

    private

    def encrypted_data(xml)
      attrs = {
        "xmlns:xenc" => XMLENC_NS,
        Type: "#{XMLENC_NS}Element"
      }

      xml["xenc"].EncryptedData(attrs) do
        xml["xenc"].EncryptionMethod(Algorithm: AES256_CBC)
        key_info(xml)
        cipher_data(xml, ciphertext)
      end
    end

    def key_info(xml)
      xml["ds"].KeyInfo("xmlns:ds" => XMLDSIG_NS) do
        xml["xenc"].EncryptedKey do
          xml["xenc"].EncryptionMethod(Algorithm: RSA_OAEP)
          cipher_data(xml, wrapped_key)
        end
      end
    end

    def cipher_data(xml, value)
      xml["xenc"].CipherData do
        xml["xenc"].CipherValue(value)
      end
    end

    def wrapped_key
      public_key = @certificate.x509.public_key
      padding = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      [public_key.public_encrypt(@aes_key, padding)].pack("m0")
    end

    def ciphertext
      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.encrypt
      cipher.key = @aes_key
      iv = cipher.random_iv
      plaintext = @element.to_xml(save_with: 0)
      [iv + cipher.update(plaintext) + cipher.final].pack("m0")
    end
  end
end
