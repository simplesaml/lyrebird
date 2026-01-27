# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class AssertionTest < Minitest::Test
    def setup
      @assertion = Assertion.new.document
      @root = @assertion.root
      @subject = @root.elements["saml:Subject"]
      @sc = @subject.elements["saml:SubjectConfirmation"]
      @scd = @sc.elements["saml:SubjectConfirmationData"]
      @conditions = @root.elements["saml:Conditions"]
      @audience_restriction = @conditions.elements["saml:AudienceRestriction"]
      @authn_statement = @root.elements["saml:AuthnStatement"]
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
      assertion = Assertion.new(issuer: "https://test.example.com").document
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
      assertion = Assertion.new(name_id: email).document
      name_id = assertion.root.elements["saml:Subject/saml:NameID"]
      assert_equal email, name_id.text
    end

    def test_name_id_format_override
      format = NAMEID_PERSISTENT
      refute_equal format, DEFAULTS.name_id_format
      assertion = Assertion.new(name_id_format: format).document
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
      assertion = Assertion.new(recipient: recipient).document
      subject = assertion.root.elements["saml:Subject"]
      sc = subject.elements["saml:SubjectConfirmation"]
      scd = sc.elements["saml:SubjectConfirmationData"]
      assert_equal recipient, scd.attributes["Recipient"]
    end

    def test_in_response_to_override
      in_response_to = "_custom_request"
      refute_equal in_response_to, DEFAULTS.in_response_to
      assertion = Assertion.new(in_response_to: in_response_to).document
      subject = assertion.root.elements["saml:Subject"]
      sc = subject.elements["saml:SubjectConfirmation"]
      scd = sc.elements["saml:SubjectConfirmationData"]
      assert_equal in_response_to, scd.attributes["InResponseTo"]
    end

    def test_in_response_to_omitted_when_nil
      assertion = Assertion.new(in_response_to: nil).document
      subject = assertion.root.elements["saml:Subject"]
      sc = subject.elements["saml:SubjectConfirmation"]
      scd = sc.elements["saml:SubjectConfirmationData"]
      assert_nil scd.attributes["InResponseTo"]
    end

    def test_valid_for_override
      valid_for = 600 # 10 minutes
      refute_equal valid_for, DEFAULTS.valid_for
      assertion = Assertion.new(valid_for: valid_for).document
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

    def test_conditions_not_before_override
      not_before = Time.now.utc - 60
      assertion = Assertion.new(not_before: not_before).document
      conditions = assertion.root.elements["saml:Conditions"]
      assert_equal not_before.iso8601, conditions.attributes["NotBefore"]
    end

    def test_conditions_not_on_or_after
      not_on_or_after = Time.iso8601(@conditions.attributes["NotOnOrAfter"])
      expected = Time.now.utc + DEFAULTS.valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_conditions_valid_for_override
      valid_for = 600 # 10 minutes
      refute_equal valid_for, DEFAULTS.valid_for
      assertion = Assertion.new(valid_for: valid_for).document
      conditions = assertion.root.elements["saml:Conditions"]
      not_on_or_after = Time.iso8601(conditions.attributes["NotOnOrAfter"])
      expected = Time.now.utc + valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_audience_restriction
      assert_equal "AudienceRestriction", @audience_restriction.name
      assert_equal "saml", @audience_restriction.prefix
    end

    def test_audience
      audience = @audience_restriction.elements["saml:Audience"]
      assert_equal "Audience", audience.name
      assert_equal "saml", audience.prefix
      assert_equal DEFAULTS.audience, audience.text
    end

    def test_audience_override
      audience = "https://custom.sp.example.com"
      refute_equal audience, DEFAULTS.audience
      assertion = Assertion.new(audience: audience).document
      conditions = assertion.root.elements["saml:Conditions"]
      ar = conditions.elements["saml:AudienceRestriction"]
      assert_equal audience, ar.elements["saml:Audience"].text
    end

    def test_authn_statement
      assert_equal "AuthnStatement", @authn_statement.name
      assert_equal "saml", @authn_statement.prefix
    end

    def test_authn_statement_authn_instant
      authn_instant = Time.iso8601(@authn_statement.attributes["AuthnInstant"])
      assert_in_delta Time.now.to_i, authn_instant.to_i, 1
    end

    def test_authn_statement_session_index
      assert @authn_statement.attributes["SessionIndex"].start_with?("_")
    end

    def test_authn_context
      authn_context = @authn_statement.elements["saml:AuthnContext"]
      assert_equal "AuthnContext", authn_context.name
      assert_equal "saml", authn_context.prefix
    end

    def test_authn_context_class_ref
      ac = @authn_statement.elements["saml:AuthnContext"]
      class_ref = ac.elements["saml:AuthnContextClassRef"]
      assert_equal "AuthnContextClassRef", class_ref.name
      assert_equal "saml", class_ref.prefix
      assert_equal DEFAULTS.authn_context, class_ref.text
    end

    def test_authn_context_override
      custom_ref = "urn:oasis:names:tc:SAML:2.0:ac:classes:Password"
      refute_equal custom_ref, DEFAULTS.authn_context
      assertion = Assertion.new(authn_context: custom_ref).document
      as = assertion.root.elements["saml:AuthnStatement"]
      ac = as.elements["saml:AuthnContext"]
      class_ref = ac.elements["saml:AuthnContextClassRef"]
      assert_equal custom_ref, class_ref.text
    end

    def test_default_attributes
      as = @root.elements["saml:AttributeStatement"]
      attrs = as.elements.to_a("saml:Attribute")
      assert_equal 2, attrs.size

      first = attrs.find { |a| a.attributes["Name"] == "first_name" }
      assert_equal "Test", first.elements["saml:AttributeValue"].text

      last = attrs.find { |a| a.attributes["Name"] == "last_name" }
      assert_equal "User", last.elements["saml:AttributeValue"].text
    end

    def test_no_attribute_statement_when_empty
      assertion = Assertion.new(attributes: {}).document
      assert_nil assertion.root.elements["saml:AttributeStatement"]
    end

    def test_attribute_statement_with_single_value
      attributes = { "email" => "user@example.com" }
      assertion = Assertion.new(attributes: attributes).document
      as = assertion.root.elements["saml:AttributeStatement"]
      assert_equal "AttributeStatement", as.name
      assert_equal "saml", as.prefix
    end

    def test_attribute_name_and_format
      attributes = { "email" => "user@example.com" }
      assertion = Assertion.new(attributes: attributes).document
      attr = assertion.root.elements["saml:AttributeStatement/saml:Attribute"]
      assert_equal "Attribute", attr.name
      assert_equal "saml", attr.prefix
      assert_equal "email", attr.attributes["Name"]
      assert_equal ATTR_NAME_FORMAT, attr.attributes["NameFormat"]
    end

    def test_attribute_single_value
      attributes = { "email" => "user@example.com" }
      assertion = Assertion.new(attributes: attributes).document
      attr = assertion.root.elements["saml:AttributeStatement/saml:Attribute"]
      value = attr.elements["saml:AttributeValue"]
      assert_equal "AttributeValue", value.name
      assert_equal "saml", value.prefix
      assert_equal "user@example.com", value.text
    end

    def test_attribute_multi_value
      attributes = { "groups" => ["admin", "users", "developers"] }
      assertion = Assertion.new(attributes: attributes).document
      attr = assertion.root.elements["saml:AttributeStatement/saml:Attribute"]
      values = attr.elements.to_a("saml:AttributeValue")
      assert_equal 3, values.size
      assert_equal "admin", values[0].text
      assert_equal "users", values[1].text
      assert_equal "developers", values[2].text
    end

    def test_multiple_attributes
      attributes = {
        email: "user@example.com",
        name: "Test User",
        groups: ["admin", "users"]
      }

      assertion = Assertion.new(attributes: attributes).document
      as = assertion.root.elements["saml:AttributeStatement"]
      attrs = as.elements.to_a("saml:Attribute")
      assert_equal 3, attrs.size

      email_attr = attrs.find { |a| a.attributes["Name"] == "email" }
      email_value = email_attr.elements["saml:AttributeValue"].text
      assert_equal "user@example.com", email_value

      name_attr = attrs.find { |a| a.attributes["Name"] == "name" }
      name_value = name_attr.elements["saml:AttributeValue"].text
      assert_equal "Test User", name_value

      groups_attr = attrs.find { |a| a.attributes["Name"] == "groups" }
      group_values = groups_attr.elements.to_a("saml:AttributeValue")
      assert_equal 2, group_values.size
      assert_equal "admin", group_values[0].text
      assert_equal "users", group_values[1].text
    end
  end
end
