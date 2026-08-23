# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class EncryptionTest < Minitest::Test
    NS = {
      "saml" => SAML_ASSERTION_NS,
      "xenc" => XMLENC_NS,
      "ds" => XMLDSIG_NS
    }.freeze

    def setup
      unless defined?(@@certificate)
        @@assertion = Assertion.new.document
        @@element = @@assertion.root
        @@certificate = Certificate.build
        @@encrypted = Encryption.new(@@element, @@certificate).encrypt
      end

      @assertion = @@assertion
      @element = @@element
      @certificate = @@certificate
      @encrypted = @@encrypted
      @ed = @encrypted.at_xpath("xenc:EncryptedData", NS)
      @ki = @ed.at_xpath("ds:KeyInfo", NS)
      @ek = @ki.at_xpath("xenc:EncryptedKey", NS)
      @cd = @ed.at_xpath("xenc:CipherData", NS)
    end

    def test_returns_encrypted_assertion_element
      assert_equal "EncryptedAssertion", @encrypted.name
      assert_equal "saml", @encrypted.namespace.prefix
    end

    def test_encrypted_assertion_namespace
      assert_equal SAML_ASSERTION_NS, @encrypted.namespace.href
    end

    def test_encrypted_data_element
      assert_equal "EncryptedData", @ed.name
      assert_equal "xenc", @ed.namespace.prefix
    end

    def test_encrypted_data_namespace
      assert_equal XMLENC_NS, @ed.namespace.href
    end

    def test_encrypted_data_type
      assert_equal "#{XMLENC_NS}Element", @ed["Type"]
    end

    def test_encryption_method_element
      em = @ed.at_xpath("xenc:EncryptionMethod", NS)
      assert_equal "EncryptionMethod", em.name
      assert_equal "xenc", em.namespace.prefix
    end

    def test_encryption_method_algorithm
      em = @ed.at_xpath("xenc:EncryptionMethod", NS)
      assert_equal AES256_CBC, em["Algorithm"]
    end

    def test_cipher_data_element
      assert_equal "CipherData", @cd.name
      assert_equal "xenc", @cd.namespace.prefix
    end

    def test_cipher_value_element
      cv = @cd.at_xpath("xenc:CipherValue", NS)
      assert_equal "CipherValue", cv.name
      assert_equal "xenc", cv.namespace.prefix
    end

    def test_cipher_value_is_base64
      cv = @cd.at_xpath("xenc:CipherValue", NS)
      decoded = Base64.strict_decode64(cv.text)
      assert decoded.bytesize > 16
    end

    def test_cipher_value_starts_with_iv
      cv = @cd.at_xpath("xenc:CipherValue", NS)
      decoded = Base64.strict_decode64(cv.text)
      iv = decoded[0, 16]
      assert_equal 16, iv.bytesize
    end

    def test_key_info_element
      assert_equal "KeyInfo", @ki.name
      assert_equal "ds", @ki.namespace.prefix
    end

    def test_key_info_namespace
      assert_equal XMLDSIG_NS, @ki.namespace.href
    end

    def test_encrypted_key_element
      assert_equal "EncryptedKey", @ek.name
      assert_equal "xenc", @ek.namespace.prefix
    end

    def test_encrypted_key_namespace
      assert_equal XMLENC_NS, @ek.namespace.href
    end

    def test_encrypted_key_encryption_method
      em = @ek.at_xpath("xenc:EncryptionMethod", NS)
      assert_equal "EncryptionMethod", em.name
      assert_equal RSA_OAEP, em["Algorithm"]
    end

    def test_encrypted_key_cipher_data
      cd = @ek.at_xpath("xenc:CipherData", NS)
      assert_equal "CipherData", cd.name
      assert_equal "xenc", cd.namespace.prefix
    end

    def test_encrypted_key_cipher_value
      cv = @ek.at_xpath("xenc:CipherData/xenc:CipherValue", NS)
      assert_equal "CipherValue", cv.name
      assert_equal "xenc", cv.namespace.prefix
    end

    def test_encrypted_key_cipher_value_is_base64
      cv = @ek.at_xpath("xenc:CipherData/xenc:CipherValue", NS)
      decoded = Base64.strict_decode64(cv.text)
      assert decoded.bytesize > 0
    end

    def test_encrypted_key_can_be_decrypted
      cv = @ek.at_xpath("xenc:CipherData/xenc:CipherValue", NS)
      encrypted_key = Base64.strict_decode64(cv.text)
      private_key = @certificate.key
      padding = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      decrypted_key = private_key.private_decrypt(encrypted_key, padding)
      assert_equal 32, decrypted_key.bytesize
    end

    def test_ciphertext_preserves_canonical_form
      c14n = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
      padding = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      cv = @ek.at_xpath("xenc:CipherData/xenc:CipherValue", NS)
      wrapped = Base64.strict_decode64(cv.text)
      blob = Base64.strict_decode64(@cd.at_xpath("xenc:CipherValue", NS).text)

      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.decrypt
      cipher.key = @certificate.key.private_decrypt(wrapped, padding)
      cipher.iv = blob[0, 16]
      plaintext = cipher.update(blob[16..]) + cipher.final
      decrypted = Nokogiri::XML(plaintext).root

      assert_equal @element.canonicalize(c14n), decrypted.canonicalize(c14n)
    end
  end
end
