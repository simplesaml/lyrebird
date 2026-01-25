# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class ResponseTest < Minitest::Test
    def setup
      @response = Response.new
      @root = @response.document.root
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
  end
end
