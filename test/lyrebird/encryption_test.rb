# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class EncryptionTest < Minitest::Test
    def setup
      @assertion = Assertion.new.document
      @element = @assertion.root
      @certificate = Certificate.generate
      @encrypted = Encryption.new(@element, @certificate).encrypt!
    end

    def test_returns_encrypted_assertion_element
      assert_equal "EncryptedAssertion", @encrypted.name
      assert_equal "saml", @encrypted.prefix
    end

    def test_encrypted_assertion_namespace
      assert_equal SAML_ASSERTION_NS, @encrypted.namespace
    end

    def test_encrypted_data_element
      ed = @encrypted.elements["xenc:EncryptedData"]
      assert_equal "EncryptedData", ed.name
      assert_equal "xenc", ed.prefix
    end

    def test_encrypted_data_namespace
      ed = @encrypted.elements["xenc:EncryptedData"]
      assert_equal XMLENC_NS, ed.namespace
    end

    def test_encrypted_data_type
      ed = @encrypted.elements["xenc:EncryptedData"]
      assert_equal "#{XMLENC_NS}Element", ed.attributes["Type"]
    end

    def test_encryption_method_element
      em = @encrypted.elements["xenc:EncryptedData/xenc:EncryptionMethod"]
      assert_equal "EncryptionMethod", em.name
      assert_equal "xenc", em.prefix
    end

    def test_encryption_method_algorithm
      em = @encrypted.elements["xenc:EncryptedData/xenc:EncryptionMethod"]
      assert_equal AES256_CBC, em.attributes["Algorithm"]
    end

    def test_cipher_data_element
      cd = @encrypted.elements["xenc:EncryptedData/xenc:CipherData"]
      assert_equal "CipherData", cd.name
      assert_equal "xenc", cd.prefix
    end

    def test_cipher_value_element
      cv = @encrypted.elements["xenc:EncryptedData/xenc:CipherData/xenc:CipherValue"]
      assert_equal "CipherValue", cv.name
      assert_equal "xenc", cv.prefix
    end

    def test_cipher_value_is_base64
      cv = @encrypted.elements["xenc:EncryptedData/xenc:CipherData/xenc:CipherValue"]
      decoded = Base64.strict_decode64(cv.text)
      assert decoded.bytesize > 16
    end

    def test_cipher_value_starts_with_iv
      cv = @encrypted.elements["xenc:EncryptedData/xenc:CipherData/xenc:CipherValue"]
      decoded = Base64.strict_decode64(cv.text)
      iv = decoded[0, 16]
      assert_equal 16, iv.bytesize
    end
  end
end
