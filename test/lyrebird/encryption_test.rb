# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class EncryptionTest < Minitest::Test
    def setup
      @assertion = Assertion.new.document
      @element = @assertion.root
      @certificate = Certificate.build
      @encrypted = Encryption.new(@element, @certificate).encrypt
      @ed = @encrypted.elements["xenc:EncryptedData"]
      @ki = @ed.elements["ds:KeyInfo"]
      @ek = @ki.elements["xenc:EncryptedKey"]
      @cd = @ed.elements["xenc:CipherData"]
    end

    def test_returns_encrypted_assertion_element
      assert_equal "EncryptedAssertion", @encrypted.name
      assert_equal "saml", @encrypted.prefix
    end

    def test_encrypted_assertion_namespace
      assert_equal SAML_ASSERTION_NS, @encrypted.namespace
    end

    def test_encrypted_data_element
      assert_equal "EncryptedData", @ed.name
      assert_equal "xenc", @ed.prefix
    end

    def test_encrypted_data_namespace
      assert_equal XMLENC_NS, @ed.namespace
    end

    def test_encrypted_data_type
      assert_equal "#{XMLENC_NS}Element", @ed.attributes["Type"]
    end

    def test_encryption_method_element
      em = @ed.elements["xenc:EncryptionMethod"]
      assert_equal "EncryptionMethod", em.name
      assert_equal "xenc", em.prefix
    end

    def test_encryption_method_algorithm
      em = @ed.elements["xenc:EncryptionMethod"]
      assert_equal AES256_CBC, em.attributes["Algorithm"]
    end

    def test_cipher_data_element
      assert_equal "CipherData", @cd.name
      assert_equal "xenc", @cd.prefix
    end

    def test_cipher_value_element
      cv = @cd.elements["xenc:CipherValue"]
      assert_equal "CipherValue", cv.name
      assert_equal "xenc", cv.prefix
    end

    def test_cipher_value_is_base64
      cv = @cd.elements["xenc:CipherValue"]
      decoded = Base64.strict_decode64(cv.text)
      assert decoded.bytesize > 16
    end

    def test_cipher_value_starts_with_iv
      cv = @cd.elements["xenc:CipherValue"]
      decoded = Base64.strict_decode64(cv.text)
      iv = decoded[0, 16]
      assert_equal 16, iv.bytesize
    end

    def test_key_info_element
      assert_equal "KeyInfo", @ki.name
      assert_equal "ds", @ki.prefix
    end

    def test_key_info_namespace
      assert_equal XMLDSIG_NS, @ki.namespace
    end

    def test_encrypted_key_element
      assert_equal "EncryptedKey", @ek.name
      assert_equal "xenc", @ek.prefix
    end

    def test_encrypted_key_namespace
      assert_equal XMLENC_NS, @ek.namespace
    end

    def test_encrypted_key_encryption_method
      em = @ek.elements["xenc:EncryptionMethod"]
      assert_equal "EncryptionMethod", em.name
      assert_equal RSA_OAEP, em.attributes["Algorithm"]
    end

    def test_encrypted_key_cipher_data
      cd = @ek.elements["xenc:CipherData"]
      assert_equal "CipherData", cd.name
      assert_equal "xenc", cd.prefix
    end

    def test_encrypted_key_cipher_value
      cv = @ek.elements["xenc:CipherData/xenc:CipherValue"]
      assert_equal "CipherValue", cv.name
      assert_equal "xenc", cv.prefix
    end

    def test_encrypted_key_cipher_value_is_base64
      cv = @ek.elements["xenc:CipherData/xenc:CipherValue"]
      decoded = Base64.strict_decode64(cv.text)
      assert decoded.bytesize > 0
    end

    def test_encrypted_key_can_be_decrypted
      cv = @ek.elements["xenc:CipherData/xenc:CipherValue"]
      encrypted_key = Base64.strict_decode64(cv.text)
      private_key = @certificate.key
      padding = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      decrypted_key = private_key.private_decrypt(encrypted_key, padding)
      assert_equal 32, decrypted_key.bytesize
    end
  end
end
