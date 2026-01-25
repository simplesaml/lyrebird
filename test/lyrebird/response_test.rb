# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class ResponseTest < Minitest::Test
    def setup
      @response = Response.new.mimic
      @root = @response.root
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
      destination = "https://custom.example.com/acs"
      response = Response.new(destination: destination).mimic
      assert_equal destination, response.root.attributes["Destination"]
    end

    def test_in_response_to_default
      assert_equal DEFAULTS.in_response_to, @root.attributes["InResponseTo"]
    end

    def test_in_response_to_override
      response = Response.new(in_response_to: "_custom_request").mimic
      assert_equal "_custom_request", response.root.attributes["InResponseTo"]
    end

    def test_issuer
      issuer = @root.elements["saml:Issuer"]
      assert_equal "Issuer", issuer.name
      assert_equal "saml", issuer.prefix
      assert_equal DEFAULTS.issuer, issuer.text
    end

    def test_issuer_override
      response = Response.new(issuer: "https://custom.idp.example.com").mimic
      issuer = response.root.elements["saml:Issuer"]
      assert_equal "https://custom.idp.example.com", issuer.text
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
  end
end
