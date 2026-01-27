# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class ResponseTest < Minitest::Test
    def setup
      @response = Response.new
      @root = @response.document.root
    end

    def test_build_with_defaults
      response = Response.build
      root = response.document.root
      assert_equal DEFAULTS.issuer, root.elements["saml:Issuer"].text
    end

    def test_build_with_kwargs
      issuer = "https://test.example.com"
      refute_equal issuer, DEFAULTS.issuer
      response = Response.build(issuer: issuer)
      root = response.document.root
      assert_equal issuer, root.elements["saml:Issuer"].text
    end

    def test_build_with_block
      issuer = "https://test.example.com"
      refute_equal issuer, DEFAULTS.issuer
      response = Response.build { |r| r.issuer = issuer }
      root = response.document.root
      assert_equal issuer, root.elements["saml:Issuer"].text
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
      assert_equal issuer, root.elements["saml:Issuer"].text
      name_id = root.elements["saml:Assertion/saml:Subject/saml:NameID"]
      assert_equal email, name_id.text
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
      statement = root.elements["saml:Assertion/saml:AttributeStatement"]
      email_element = statement.elements["saml:Attribute[@Name='email']"]
      role_element = statement.elements["saml:Attribute[@Name='role']"]

      assert_equal email, email_element.elements["saml:AttributeValue"].text
      assert_equal role, role_element.elements["saml:AttributeValue"].text
    end

    def test_build_with_attributes_hash
      email = "user@example.com"

      response = Response.build do |r|
        r.attributes = { email: email }
      end

      root = response.document.root
      statement = root.elements["saml:Assertion/saml:AttributeStatement"]
      email_element = statement.elements["saml:Attribute[@Name='email']"]
      assert_equal email, email_element.elements["saml:AttributeValue"].text
    end

    def test_mimic_returns_base64
      encoded = @response.mimic
      decoded = Base64.strict_decode64(encoded)
      assert decoded.include?("<samlp:Response")
      assert decoded.include?("<saml:Assertion")
    end

    def test_root_name
      assert_equal "Response", @root.name
      assert_equal "samlp", @root.prefix
    end

    def test_root_namespace
      assert_equal SAML_PROTOCOL_NS, @root.namespace
    end

    def test_saml_namespace_declared
      assert_equal SAML_ASSERTION_NS, @root.namespace("saml")
    end

    def test_root_id
      assert @root.attributes["ID"].start_with?("_")
    end

    def test_root_version
      assert_equal "2.0", @root.attributes["Version"]
    end

    def test_root_issue_instant
      instant = Time.iso8601(@root.attributes["IssueInstant"])
      assert_in_delta Time.now.to_i, instant.to_i, 1
    end

    def test_destination_default
      assert_equal DEFAULTS.recipient, @root.attributes["Destination"]
    end

    def test_destination_override
      destination = "https://test.example.com/acs"
      refute_equal destination, DEFAULTS.recipient
      root = Response.new(destination: destination).document.root
      assert_equal destination, root.attributes["Destination"]
    end

    def test_in_response_to_default
      assert_equal DEFAULTS.in_response_to, @root.attributes["InResponseTo"]
    end

    def test_in_response_to_override
      in_response_to = "_test_request"
      refute_equal in_response_to, DEFAULTS.in_response_to
      root = Response.new(in_response_to: in_response_to).document.root
      assert_equal in_response_to, root.attributes["InResponseTo"]
    end

    def test_issuer
      issuer = @root.elements["saml:Issuer"]
      assert_equal "Issuer", issuer.name
      assert_equal "saml", issuer.prefix
      assert_equal DEFAULTS.issuer, issuer.text
    end

    def test_issuer_override
      url = "https://test.idp.example.com"
      refute_equal url, DEFAULTS.issuer
      root = Response.new(issuer: url).document.root
      issuer = root.elements["saml:Issuer"]
      assert_equal url, issuer.text
    end

    def test_status
      status = @root.elements["samlp:Status"]
      assert_equal "Status", status.name
      assert_equal "samlp", status.prefix
    end

    def test_status_code
      status_code = @root.elements["samlp:Status/samlp:StatusCode"]
      assert_equal "StatusCode", status_code.name
      assert_equal "samlp", status_code.prefix
      assert_equal STATUS_SUCCESS, status_code.attributes["Value"]
    end

    def test_assertion_embedded
      assertion = @root.elements["saml:Assertion"]
      assert_equal "Assertion", assertion.name
      assert_equal "saml", assertion.prefix
    end

    def test_assertion_has_id
      assertion = @root.elements["saml:Assertion"]
      assert assertion.attributes["ID"].start_with?("_")
    end

    def test_assertion_inherits_issuer
      url = "https://test.idp.example.com"
      refute_equal url, DEFAULTS.issuer
      root = Response.new(issuer: url).document.root
      assertion = root.elements["saml:Assertion"]
      issuer = assertion.elements["saml:Issuer"]
      assert_equal url, issuer.text
    end

    def test_assertion_options_flow_through
      email = "test@example.com"
      refute_equal email, DEFAULTS.name_id
      root = Response.new(name_id: email).document.root
      assertion = root.elements["saml:Assertion"]
      name_id = assertion.elements["saml:Subject/saml:NameID"]
      assert_equal email, name_id.text
    end

    def test_assertion_unsigned_by_default
      assertion = @root.elements["saml:Assertion"]
      assert_nil assertion.elements["ds:Signature"]
    end

    def test_sign_assertion_adds_signature
      cert = Certificate.generate
      root = Response.new(idp_certificate: cert, sign_assertion: true).document.root
      assertion = root.elements["saml:Assertion"]
      signature = assertion.elements["ds:Signature"]
      assert_equal "Signature", signature.name
      assert_equal "ds", signature.prefix
    end

    def test_response_unsigned_by_default
      assert_nil @root.elements["ds:Signature"]
    end

    def test_sign_response_adds_signature
      args = { idp_certificate: Certificate.generate, sign_response: true }
      root = Response.new(**args).document.root
      signature = root.elements["ds:Signature"]
      assert_equal "Signature", signature.name
      assert_equal "ds", signature.prefix
    end

    def test_sign_both_response_and_assertion
      args = {
        idp_certificate: Certificate.generate,
        sign_assertion: true,
        sign_response: true
      }

      root = Response.new(**args).document.root
      refute_nil root.elements["ds:Signature"]
      refute_nil root.elements["saml:Assertion/ds:Signature"]
    end

    def test_sign_neither_response_nor_assertion
      root = Response.new(idp_certificate: Certificate.generate).document.root
      assert_nil root.elements["ds:Signature"]
      assert_nil root.elements["saml:Assertion/ds:Signature"]
    end

    def test_assertion_not_encrypted_by_default
      assert_nil @root.elements["saml:EncryptedAssertion"]
    end

    def test_encrypt_assertion_creates_encrypted_assertion
      sp_cert = Certificate.generate
      args = { encrypt_assertion: true, sp_certificate: sp_cert }
      root = Response.new(**args).document.root
      ea = root.elements["saml:EncryptedAssertion"]
      assert_equal "EncryptedAssertion", ea.name
      assert_equal "saml", ea.prefix
    end

    def test_encrypt_assertion_removes_plain_assertion
      sp_cert = Certificate.generate
      args = { encrypt_assertion: true, sp_certificate: sp_cert }
      root = Response.new(**args).document.root
      assert_nil root.elements["saml:Assertion"]
    end

    def test_encrypt_assertion_contains_encrypted_data
      sp_cert = Certificate.generate
      args = { encrypt_assertion: true, sp_certificate: sp_cert }
      root = Response.new(**args).document.root
      ed = root.elements["saml:EncryptedAssertion/xenc:EncryptedData"]
      assert_equal "EncryptedData", ed.name
    end

  end
end
