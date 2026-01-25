# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class AssertionTest < Minitest::Test
    def setup
      @assertion = Assertion.new.mimic
      @root = @assertion.root
      @subject = @root.elements["saml:Subject"]
      @sc = @subject.elements["saml:SubjectConfirmation"]
      @scd = @sc.elements["saml:SubjectConfirmationData"]
      @conditions = @root.elements["saml:Conditions"]
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
      assert_equal "Subject", @subject.name
      assert_equal "saml", @subject.prefix
    end

    def test_name_id
      name_id = @subject.elements["saml:NameID"]
      assert_equal "NameID", name_id.name
      assert_equal "saml", name_id.prefix
      assert_equal DEFAULTS.name_id, name_id.text
    end

    def test_name_id_format_default
      name_id = @subject.elements["saml:NameID"]
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

    def test_subject_confirmation
      assert_equal "SubjectConfirmation", @sc.name
      assert_equal "saml", @sc.prefix
    end

    def test_subject_confirmation_method
      assert_equal CM_BEARER, @sc.attributes["Method"]
    end

    def test_subject_confirmation_data
      assert_equal "SubjectConfirmationData", @scd.name
      assert_equal "saml", @scd.prefix
    end

    def test_valid_for_default
      not_on_or_after = Time.iso8601(@scd.attributes["NotOnOrAfter"])
      expected = Time.now.utc + DEFAULTS.valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_recipient_default
      assert_equal DEFAULTS.recipient, @scd.attributes["Recipient"]
    end

    def test_in_response_to_default
      assert_equal DEFAULTS.in_response_to, @scd.attributes["InResponseTo"]
    end

    def test_recipient_override
      recipient = "https://custom.example.com/acs"
      refute_equal recipient, DEFAULTS.recipient
      assertion = Assertion.new(recipient: recipient).mimic
      subject = assertion.root.elements["saml:Subject"]
      sc = subject.elements["saml:SubjectConfirmation"]
      scd = sc.elements["saml:SubjectConfirmationData"]
      assert_equal recipient, scd.attributes["Recipient"]
    end

    def test_in_response_to_override
      in_response_to = "_custom_request"
      refute_equal in_response_to, DEFAULTS.in_response_to
      assertion = Assertion.new(in_response_to: in_response_to).mimic
      subject = assertion.root.elements["saml:Subject"]
      sc = subject.elements["saml:SubjectConfirmation"]
      scd = sc.elements["saml:SubjectConfirmationData"]
      assert_equal in_response_to, scd.attributes["InResponseTo"]
    end

    def test_valid_for_override
      valid_for = 600 # 10 minutes
      refute_equal valid_for, DEFAULTS.valid_for
      assertion = Assertion.new(valid_for: valid_for).mimic
      subject = assertion.root.elements["saml:Subject"]
      sc = subject.elements["saml:SubjectConfirmation"]
      scd = sc.elements["saml:SubjectConfirmationData"]
      not_on_or_after = Time.iso8601(scd.attributes["NotOnOrAfter"])
      expected = Time.now.utc + valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_conditions
      assert_equal "Conditions", @conditions.name
      assert_equal "saml", @conditions.prefix
    end

    def test_conditions_not_before
      not_before = Time.iso8601(@conditions.attributes["NotBefore"])
      assert_in_delta Time.now.to_i, not_before.to_i, 1
    end

    def test_conditions_not_on_or_after
      not_on_or_after = Time.iso8601(@conditions.attributes["NotOnOrAfter"])
      expected = Time.now.utc + DEFAULTS.valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_conditions_valid_for_override
      valid_for = 600 # 10 minutes
      refute_equal valid_for, DEFAULTS.valid_for
      assertion = Assertion.new(valid_for: valid_for).mimic
      conditions = assertion.root.elements["saml:Conditions"]
      not_on_or_after = Time.iso8601(conditions.attributes["NotOnOrAfter"])
      expected = Time.now.utc + valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end
  end
end
