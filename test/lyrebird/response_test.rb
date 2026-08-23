# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class ResponseTest < Minitest::Test
    NAMESPACES = {
      "saml" => SAML_ASSERTION_NS,
      "samlp" => SAML_PROTOCOL_NS,
      "ds" => XMLDSIG_NS,
      "xenc" => XMLENC_NS
    }.freeze

    def setup
      @response = Response.new
      @root = @response.document.root
    end

    def test_build_with_defaults
      response = Response.build
      root = response.document.root
      issuer = root.at_xpath("saml:Issuer", NAMESPACES)
      assert_equal DEFAULTS.issuer, issuer.text
    end

    def test_build_with_kwargs
      issuer = "https://test.example.com"
      refute_equal issuer, DEFAULTS.issuer
      response = Response.build(issuer: issuer)
      root = response.document.root
      assert_equal issuer, root.at_xpath("saml:Issuer", NAMESPACES).text
    end

    def test_build_with_block
      issuer = "https://test.example.com"
      refute_equal issuer, DEFAULTS.issuer
      response = Response.build { |r| r.issuer = issuer }
      root = response.document.root
      assert_equal issuer, root.at_xpath("saml:Issuer", NAMESPACES).text
    end

    def test_build_with_kwargs_and_block
      issuer = "https://test.example.com"
      email = "test@example.com"

      refute_equal issuer, DEFAULTS.issuer
      refute_equal email, DEFAULTS.name_id

      response = Response.build(issuer: issuer) do |r|
        r.name_id = email
      end

      root = response.document.root
      assert_equal issuer, root.at_xpath("saml:Issuer", NAMESPACES).text
      xpath = "saml:Assertion/saml:Subject/saml:NameID"
      assert_equal email, root.at_xpath(xpath, NAMESPACES).text
    end

    def test_build_with_attributes_block
      email = "test@example.com"
      role = "admin"

      response = Response.build do |r|
        r.attributes do |a|
          a.email = email
          a.role = role
        end
      end

      root = response.document.root
      statement_xpath = "saml:Assertion/saml:AttributeStatement"
      statement = root.at_xpath(statement_xpath, NAMESPACES)
      email_xpath = "saml:Attribute[@Name='email']/saml:AttributeValue"
      role_xpath = "saml:Attribute[@Name='role']/saml:AttributeValue"
      email_element = statement.at_xpath(email_xpath, NAMESPACES)
      role_element = statement.at_xpath(role_xpath, NAMESPACES)

      assert_equal email, email_element.text
      assert_equal role, role_element.text
    end

    def test_build_with_attributes_hash
      email = "user@example.com"

      response = Response.build do |r|
        r.attributes = { email: email }
      end

      root = response.document.root
      statement_xpath = "saml:Assertion/saml:AttributeStatement"
      attr_xpath = "saml:Attribute[@Name='email']/saml:AttributeValue"
      statement = root.at_xpath(statement_xpath, NAMESPACES)
      assert_equal email, statement.at_xpath(attr_xpath, NAMESPACES).text
    end

    def test_mimic_returns_base64
      encoded = @response.mimic
      decoded = Base64.strict_decode64(encoded)
      assert decoded.include?("<samlp:Response")
      assert decoded.include?("<saml:Assertion")
    end

    def test_document_is_memoized
      assert_same @response.document, @response.document
    end

    def test_mimic_is_stable
      assert_equal @response.mimic, @response.mimic
    end

    def test_root_name
      assert_equal "Response", @root.name
      assert_equal "samlp", @root.namespace.prefix
    end

    def test_root_namespace
      assert_equal SAML_PROTOCOL_NS, @root.namespace.href
    end

    def test_saml_namespace_declared
      assert_equal SAML_ASSERTION_NS, @root.namespaces["xmlns:saml"]
    end

    def test_root_id
      assert @root["ID"].start_with?("_")
    end

    def test_root_version
      assert_equal "2.0", @root["Version"]
    end

    def test_root_issue_instant
      instant = Time.iso8601(@root["IssueInstant"])
      assert_in_delta Time.now.to_i, instant.to_i, 1
    end

    def test_destination_default
      assert_equal DEFAULTS.recipient, @root["Destination"]
    end

    def test_destination_override
      destination = "https://test.example.com/acs"
      refute_equal destination, DEFAULTS.recipient
      root = Response.new(destination: destination).document.root
      assert_equal destination, root["Destination"]
    end

    def test_in_response_to_default
      assert_equal DEFAULTS.in_response_to, @root["InResponseTo"]
    end

    def test_in_response_to_override
      in_response_to = "_test_request"
      refute_equal in_response_to, DEFAULTS.in_response_to
      root = Response.new(in_response_to: in_response_to).document.root
      assert_equal in_response_to, root["InResponseTo"]
    end

    def test_destination_omitted_when_nil
      root = Response.new(destination: nil).document.root
      assert_nil root["Destination"]
    end

    def test_in_response_to_omitted_when_nil
      root = Response.new(in_response_to: nil).document.root
      assert_nil root["InResponseTo"]
    end

    def test_issuer
      issuer = @root.at_xpath("saml:Issuer", NAMESPACES)
      assert_equal "Issuer", issuer.name
      assert_equal "saml", issuer.namespace.prefix
      assert_equal DEFAULTS.issuer, issuer.text
    end

    def test_issuer_override
      url = "https://test.idp.example.com"
      refute_equal url, DEFAULTS.issuer
      root = Response.new(issuer: url).document.root
      issuer = root.at_xpath("saml:Issuer", NAMESPACES)
      assert_equal url, issuer.text
    end

    def test_status
      status = @root.at_xpath("samlp:Status", NAMESPACES)
      assert_equal "Status", status.name
      assert_equal "samlp", status.namespace.prefix
    end

    def test_status_code
      status_code = @root.at_xpath("samlp:Status/samlp:StatusCode", NAMESPACES)
      assert_equal "StatusCode", status_code.name
      assert_equal "samlp", status_code.namespace.prefix
      assert_equal STATUS_SUCCESS, status_code["Value"]
    end

    def test_assertion_embedded
      assertion = @root.at_xpath("saml:Assertion", NAMESPACES)
      assert_equal "Assertion", assertion.name
      assert_equal "saml", assertion.namespace.prefix
    end

    def test_assertion_has_id
      assertion = @root.at_xpath("saml:Assertion", NAMESPACES)
      assert assertion["ID"].start_with?("_")
    end

    def test_assertion_inherits_issuer
      url = "https://test.idp.example.com"
      refute_equal url, DEFAULTS.issuer
      root = Response.new(issuer: url).document.root
      issuer = root.at_xpath("saml:Assertion/saml:Issuer", NAMESPACES)
      assert_equal url, issuer.text
    end

    def test_assertion_options_flow_through
      email = "test@example.com"
      refute_equal email, DEFAULTS.name_id
      root = Response.new(name_id: email).document.root
      xpath = "saml:Assertion/saml:Subject/saml:NameID"
      assert_equal email, root.at_xpath(xpath, NAMESPACES).text
    end

    def test_unsigned_by_default
      assert_nil @root.at_xpath("ds:Signature", NAMESPACES)
      assert_nil @root.at_xpath("saml:Assertion/ds:Signature", NAMESPACES)
    end

    def test_sign_with_signs_response_and_assertion
      root = Response.new(sign_with: Certificate.build).document.root
      refute_nil root.at_xpath("ds:Signature", NAMESPACES)
      refute_nil root.at_xpath("saml:Assertion/ds:Signature", NAMESPACES)
    end

    def test_not_encrypted_by_default
      assert_nil @root.at_xpath("saml:EncryptedAssertion", NAMESPACES)
    end

    def test_encrypt_with_creates_encrypted_assertion
      root = Response.new(encrypt_with: Certificate.build).document.root
      ea = root.at_xpath("saml:EncryptedAssertion", NAMESPACES)
      assert_equal "EncryptedAssertion", ea.name
      assert_equal "saml", ea.namespace.prefix
    end

    def test_encrypt_with_removes_plain_assertion
      root = Response.new(encrypt_with: Certificate.build).document.root
      assert_nil root.at_xpath("saml:Assertion", NAMESPACES)
    end

    def test_encrypt_with_contains_encrypted_data
      root = Response.new(encrypt_with: Certificate.build).document.root
      xpath = "saml:EncryptedAssertion/xenc:EncryptedData"
      ed = root.at_xpath(xpath, NAMESPACES)
      assert_equal "EncryptedData", ed.name
    end

    def test_encrypted_assertion_signature_verifies_after_decryption
      idp = Certificate.build
      sp = Certificate.build
      root = Response.new(sign_with: idp, encrypt_with: sp).document.root

      c14n = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
      padding = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      key_xpath = "//xenc:EncryptedKey/xenc:CipherData/xenc:CipherValue"
      data_xpath = "//xenc:EncryptedData/xenc:CipherData/xenc:CipherValue"
      key_cv = root.at_xpath(key_xpath, NAMESPACES)
      encrypted_key = Base64.strict_decode64(key_cv.text)
      blob = Base64.strict_decode64(root.at_xpath(data_xpath, NAMESPACES).text)

      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.decrypt
      cipher.key = sp.key.private_decrypt(encrypted_key, padding)
      cipher.iv = blob[0, 16]
      plaintext = cipher.update(blob[16..]) + cipher.final
      assertion = Nokogiri::XML(plaintext).root

      signature = assertion.at_xpath("ds:Signature", NAMESPACES)
      signed_info = signature.at_xpath("ds:SignedInfo", NAMESPACES)
      digest_xpath = "ds:Reference/ds:DigestValue"
      digest_value = signed_info.at_xpath(digest_xpath, NAMESPACES).text
      sv = signature.at_xpath("ds:SignatureValue", NAMESPACES).text

      verified = idp.x509.public_key.verify(
        "SHA256",
        Base64.strict_decode64(sv),
        signed_info.canonicalize(c14n)
      )

      assert verified, "SignedInfo signature did not verify"

      signature.remove
      digest = OpenSSL::Digest::SHA256.digest(assertion.canonicalize(c14n))
      assert_equal digest_value, Base64.strict_encode64(digest)
    end
  end
end
