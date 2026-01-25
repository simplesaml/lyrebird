# frozen_string_literal: true

module Lyrebird
  class Encryption
    def initialize(element, certificate)
      @element = element
      @certificate = certificate
      @aes_key = SecureRandom.random_bytes(32)
    end

    def encrypt!
      encrypted_assertion
    end

    private

    def encrypted_assertion
      REXML::Element.new("saml:EncryptedAssertion").tap do |ea|
        ea.add_namespace("saml", SAML_ASSERTION_NS)
        ea.add_element(encrypted_data)
      end
    end

    def encrypted_data
      REXML::Element.new("xenc:EncryptedData").tap do |ed|
        ed.add_namespace("xenc", XMLENC_NS)
        ed.add_attribute("Type", "#{XMLENC_NS}Element")
        em = ed.add_element("xenc:EncryptionMethod")
        em.add_attribute("Algorithm", AES256_CBC)
        ed.add_element(cipher_data)
      end
    end

    def cipher_data
      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.encrypt
      cipher.key = @aes_key
      iv = cipher.random_iv
      ciphertext = cipher.update(@element.to_s) + cipher.final

      REXML::Element.new("xenc:CipherData").tap do |cd|
        cv = Base64.strict_encode64(iv + ciphertext)
        cd.add_element("xenc:CipherValue").text = cv
      end
    end
  end
end
