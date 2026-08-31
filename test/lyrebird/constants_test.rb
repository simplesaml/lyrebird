# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class ConstantsTest < Minitest::Test
    def test_saml_assertion_ns
      assert_equal "urn:oasis:names:tc:SAML:2.0:assertion", SAML_ASSERTION_NS
    end

    def test_saml_protocol_ns
      assert_equal "urn:oasis:names:tc:SAML:2.0:protocol", SAML_PROTOCOL_NS
    end

    def test_nameid_email
      expected = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
      assert_equal expected, NAMEID_EMAIL
    end

    def test_nameid_persistent
      expected = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
      assert_equal expected, NAMEID_PERSISTENT
    end

    def test_nameid_transient
      expected = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
      assert_equal expected, NAMEID_TRANSIENT
    end

    def test_nameid_unspecified
      expected = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
      assert_equal expected, NAMEID_UNSPECIFIED
    end

    def test_cm_bearer
      assert_equal "urn:oasis:names:tc:SAML:2.0:cm:bearer", CM_BEARER
    end

    def test_attr_name_format
      expected = "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"
      assert_equal expected, ATTR_NAME_FORMAT
    end

    def test_status_success
      assert_equal "urn:oasis:names:tc:SAML:2.0:status:Success", STATUS_SUCCESS
    end

    def test_xmldsig_ns
      assert_equal "http://www.w3.org/2000/09/xmldsig#", XMLDSIG_NS
    end

    def test_enveloped_sig
      expected = "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
      assert_equal expected, ENVELOPED_SIG
    end

    def test_exc_c14n
      assert_equal "http://www.w3.org/2001/10/xml-exc-c14n#", EXC_C14N
    end

    def test_sha256_digest
      assert_equal "http://www.w3.org/2001/04/xmlenc#sha256", SHA256_DIGEST
    end

    def test_rsa_sha256
      expected = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
      assert_equal expected, RSA_SHA256
    end

    def test_xmlenc_ns
      assert_equal "http://www.w3.org/2001/04/xmlenc#", XMLENC_NS
    end

    def test_aes256_cbc
      assert_equal "http://www.w3.org/2001/04/xmlenc#aes256-cbc", AES256_CBC
    end

    def test_rsa_oaep
      expected = "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
      assert_equal expected, RSA_OAEP
    end
  end
end
