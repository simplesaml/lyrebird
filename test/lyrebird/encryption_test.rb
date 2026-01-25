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
  end
end
