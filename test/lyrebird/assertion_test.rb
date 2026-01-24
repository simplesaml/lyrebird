# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class AssertionTest < Minitest::Test
    def setup
      @assertion = Assertion.new.mimic
      @root = @assertion.root
    end

    def test_root_name
      assert_equal "Assertion", @root.name
      assert_equal "saml", @root.prefix
    end

    def test_root_namespace
      assert_equal SAML_ASSERTION_NS, @root.namespace
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

    def test_issuer
      issuer = @root.elements["saml:Issuer"]
      assert_equal "Issuer", issuer.name
      assert_equal "saml", issuer.prefix
      assert_equal DEFAULTS.issuer, issuer.text
    end

    def test_issuer_override
      assertion = Assertion.new(issuer: "https://test.example.com").mimic
      issuer = assertion.root.elements["saml:Issuer"]
      assert_equal "https://test.example.com", issuer.text
    end

    def test_subject
      subject = @root.elements["saml:Subject"]
      assert_equal "Subject", subject.name
      assert_equal "saml", subject.prefix
    end

    def test_name_id
      name_id = @root.elements["saml:Subject/saml:NameID"]
      assert_equal "NameID", name_id.name
      assert_equal "saml", name_id.prefix
      assert_equal DEFAULTS.name_id, name_id.text
    end

    def test_name_id_format_default
      name_id = @root.elements["saml:Subject/saml:NameID"]
      assert_equal NAMEID_EMAIL, name_id.attributes["Format"]
    end

    def test_name_id_override
      email = "user@test.com"
      refute_equal email, DEFAULTS.name_id
      assertion = Assertion.new(name_id: email).mimic
      name_id = assertion.root.elements["saml:Subject/saml:NameID"]
      assert_equal email, name_id.text
    end

    def test_name_id_format_override
      format = NAMEID_PERSISTENT
      refute_equal format, DEFAULTS.name_id_format
      assertion = Assertion.new(name_id_format: format).mimic
      name_id = assertion.root.elements["saml:Subject/saml:NameID"]
      assert_equal format, name_id.attributes["Format"]
    end
  end
end
