# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class AssertionTest < Minitest::Test
    NS = { "saml" => SAML_ASSERTION_NS }.freeze

    def setup
      @assertion = Assertion.new.document
      @root = @assertion.root
      @subject = @root.at_xpath("saml:Subject", NS)
      @sc = @subject.at_xpath("saml:SubjectConfirmation", NS)
      @scd = @sc.at_xpath("saml:SubjectConfirmationData", NS)
      @conditions = @root.at_xpath("saml:Conditions", NS)
      xpath = "saml:AudienceRestriction"
      @audience_restriction = @conditions.at_xpath(xpath, NS)
      @authn_statement = @root.at_xpath("saml:AuthnStatement", NS)
    end

    def test_root_name
      assert_equal "Assertion", @root.name
      assert_equal "saml", @root.namespace.prefix
    end

    def test_document_is_memoized
      assertion = Assertion.new
      assert_same assertion.document, assertion.document
    end

    def test_root_namespace
      assert_equal SAML_ASSERTION_NS, @root.namespace.href
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

    def test_issuer
      issuer = @root.at_xpath("saml:Issuer", NS)
      assert_equal "Issuer", issuer.name
      assert_equal "saml", issuer.namespace.prefix
      assert_equal DEFAULTS.issuer, issuer.text
    end

    def test_issuer_override
      assertion = Assertion.new(issuer: "https://test.example.com").document
      issuer = assertion.root.at_xpath("saml:Issuer", NS)
      assert_equal "https://test.example.com", issuer.text
    end

    def test_subject
      assert_equal "Subject", @subject.name
      assert_equal "saml", @subject.namespace.prefix
    end

    def test_name_id
      name_id = @subject.at_xpath("saml:NameID", NS)
      assert_equal "NameID", name_id.name
      assert_equal "saml", name_id.namespace.prefix
      assert_equal DEFAULTS.name_id, name_id.text
    end

    def test_name_id_format_default
      name_id = @subject.at_xpath("saml:NameID", NS)
      assert_equal NAMEID_EMAIL, name_id["Format"]
    end

    def test_name_id_override
      email = "user@test.com"
      refute_equal email, DEFAULTS.name_id
      assertion = Assertion.new(name_id: email).document
      name_id = assertion.root.at_xpath("saml:Subject/saml:NameID", NS)
      assert_equal email, name_id.text
    end

    def test_name_id_format_override
      format = NAMEID_PERSISTENT
      refute_equal format, DEFAULTS.name_id_format
      assertion = Assertion.new(name_id_format: format).document
      name_id = assertion.root.at_xpath("saml:Subject/saml:NameID", NS)
      assert_equal format, name_id["Format"]
    end

    def test_subject_confirmation
      assert_equal "SubjectConfirmation", @sc.name
      assert_equal "saml", @sc.namespace.prefix
    end

    def test_subject_confirmation_method
      assert_equal CM_BEARER, @sc["Method"]
    end

    def test_subject_confirmation_data
      assert_equal "SubjectConfirmationData", @scd.name
      assert_equal "saml", @scd.namespace.prefix
    end

    def test_valid_for_default
      not_on_or_after = Time.iso8601(@scd["NotOnOrAfter"])
      expected = Time.now.utc + DEFAULTS.valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_recipient_default
      assert_equal DEFAULTS.recipient, @scd["Recipient"]
    end

    def test_in_response_to_default
      assert_equal DEFAULTS.in_response_to, @scd["InResponseTo"]
    end

    def test_recipient_override
      recipient = "https://custom.example.com/acs"
      refute_equal recipient, DEFAULTS.recipient
      assertion = Assertion.new(recipient: recipient).document
      subject = assertion.root.at_xpath("saml:Subject", NS)
      sc = subject.at_xpath("saml:SubjectConfirmation", NS)
      scd = sc.at_xpath("saml:SubjectConfirmationData", NS)
      assert_equal recipient, scd["Recipient"]
    end

    def test_in_response_to_override
      in_response_to = "_custom_request"
      refute_equal in_response_to, DEFAULTS.in_response_to
      assertion = Assertion.new(in_response_to: in_response_to).document
      subject = assertion.root.at_xpath("saml:Subject", NS)
      sc = subject.at_xpath("saml:SubjectConfirmation", NS)
      scd = sc.at_xpath("saml:SubjectConfirmationData", NS)
      assert_equal in_response_to, scd["InResponseTo"]
    end

    def test_in_response_to_omitted_when_nil
      assertion = Assertion.new(in_response_to: nil).document
      subject = assertion.root.at_xpath("saml:Subject", NS)
      sc = subject.at_xpath("saml:SubjectConfirmation", NS)
      scd = sc.at_xpath("saml:SubjectConfirmationData", NS)
      assert_nil scd["InResponseTo"]
    end

    def test_valid_for_override
      valid_for = 600 # 10 minutes
      refute_equal valid_for, DEFAULTS.valid_for
      assertion = Assertion.new(valid_for: valid_for).document
      subject = assertion.root.at_xpath("saml:Subject", NS)
      sc = subject.at_xpath("saml:SubjectConfirmation", NS)
      scd = sc.at_xpath("saml:SubjectConfirmationData", NS)
      not_on_or_after = Time.iso8601(scd["NotOnOrAfter"])
      expected = Time.now.utc + valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_conditions
      assert_equal "Conditions", @conditions.name
      assert_equal "saml", @conditions.namespace.prefix
    end

    def test_conditions_not_before
      not_before = Time.iso8601(@conditions["NotBefore"])
      assert_in_delta Time.now.to_i, not_before.to_i, 1
    end

    def test_conditions_not_before_override
      not_before = Time.now.utc - 60
      assertion = Assertion.new(not_before: not_before).document
      conditions = assertion.root.at_xpath("saml:Conditions", NS)
      assert_equal not_before.iso8601, conditions["NotBefore"]
    end

    def test_conditions_not_before_coerced_to_utc
      not_before = Time.new(2030, 1, 1, 12, 0, 0, "-05:00")
      assertion = Assertion.new(not_before: not_before).document
      conditions = assertion.root.at_xpath("saml:Conditions", NS)
      assert_equal "2030-01-01T17:00:00Z", conditions["NotBefore"]
    end

    def test_not_before_does_not_mutate_caller
      not_before = Time.new(2030, 1, 1, 12, 0, 0, "-05:00")
      Assertion.new(not_before: not_before)
      assert_equal "-05:00", not_before.strftime("%:z")
    end

    def test_conditions_not_before_accepts_datetime
      not_before = DateTime.new(2030, 1, 1, 12, 0, 0, "-05:00")
      assertion = Assertion.new(not_before: not_before).document
      conditions = assertion.root.at_xpath("saml:Conditions", NS)
      assert_equal "2030-01-01T17:00:00Z", conditions["NotBefore"]
    end

    def test_conditions_not_on_or_after
      not_on_or_after = Time.iso8601(@conditions["NotOnOrAfter"])
      expected = Time.now.utc + DEFAULTS.valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_conditions_valid_for_override
      valid_for = 600 # 10 minutes
      refute_equal valid_for, DEFAULTS.valid_for
      assertion = Assertion.new(valid_for: valid_for).document
      conditions = assertion.root.at_xpath("saml:Conditions", NS)
      not_on_or_after = Time.iso8601(conditions["NotOnOrAfter"])
      expected = Time.now.utc + valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_not_on_or_after_follows_future_not_before
      not_before = Time.now.utc + 600
      assertion = Assertion.new(not_before: not_before).document
      conditions = assertion.root.at_xpath("saml:Conditions", NS)
      not_on_or_after = Time.iso8601(conditions["NotOnOrAfter"])
      expected = not_before + DEFAULTS.valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_not_on_or_after_unaffected_by_past_not_before
      assertion = Assertion.new(not_before: Time.now.utc - 3600).document
      conditions = assertion.root.at_xpath("saml:Conditions", NS)
      not_on_or_after = Time.iso8601(conditions["NotOnOrAfter"])
      expected = Time.now.utc + DEFAULTS.valid_for
      assert_in_delta expected.to_i, not_on_or_after.to_i, 1
    end

    def test_audience_restriction
      assert_equal "AudienceRestriction", @audience_restriction.name
      assert_equal "saml", @audience_restriction.namespace.prefix
    end

    def test_audience
      audience = @audience_restriction.at_xpath("saml:Audience", NS)
      assert_equal "Audience", audience.name
      assert_equal "saml", audience.namespace.prefix
      assert_equal DEFAULTS.audience, audience.text
    end

    def test_audience_override
      audience = "https://custom.sp.example.com"
      refute_equal audience, DEFAULTS.audience
      assertion = Assertion.new(audience: audience).document
      conditions = assertion.root.at_xpath("saml:Conditions", NS)
      ar = conditions.at_xpath("saml:AudienceRestriction", NS)
      assert_equal audience, ar.at_xpath("saml:Audience", NS).text
    end

    def test_authn_statement
      assert_equal "AuthnStatement", @authn_statement.name
      assert_equal "saml", @authn_statement.namespace.prefix
    end

    def test_authn_statement_authn_instant
      authn_instant = Time.iso8601(@authn_statement["AuthnInstant"])
      assert_in_delta Time.now.to_i, authn_instant.to_i, 1
    end

    def test_authn_statement_session_index
      assert @authn_statement["SessionIndex"].start_with?("_")
    end

    def test_authn_context
      authn_context = @authn_statement.at_xpath("saml:AuthnContext", NS)
      assert_equal "AuthnContext", authn_context.name
      assert_equal "saml", authn_context.namespace.prefix
    end

    def test_authn_context_class_ref
      ac = @authn_statement.at_xpath("saml:AuthnContext", NS)
      class_ref = ac.at_xpath("saml:AuthnContextClassRef", NS)
      assert_equal "AuthnContextClassRef", class_ref.name
      assert_equal "saml", class_ref.namespace.prefix
      assert_equal DEFAULTS.authn_context, class_ref.text
    end

    def test_authn_context_override
      custom_ref = "urn:oasis:names:tc:SAML:2.0:ac:classes:Password"
      refute_equal custom_ref, DEFAULTS.authn_context
      assertion = Assertion.new(authn_context: custom_ref).document
      as = assertion.root.at_xpath("saml:AuthnStatement", NS)
      ac = as.at_xpath("saml:AuthnContext", NS)
      class_ref = ac.at_xpath("saml:AuthnContextClassRef", NS)
      assert_equal custom_ref, class_ref.text
    end

    def test_default_attributes
      as = @root.at_xpath("saml:AttributeStatement", NS)
      attrs = as.xpath("saml:Attribute", NS)
      assert_equal 2, attrs.size

      first = attrs.find { |a| a["Name"] == "first_name" }
      assert_equal "Test", first.at_xpath("saml:AttributeValue", NS).text

      last = attrs.find { |a| a["Name"] == "last_name" }
      assert_equal "User", last.at_xpath("saml:AttributeValue", NS).text
    end

    def test_no_attribute_statement_when_empty
      assertion = Assertion.new(attributes: {}).document
      assert_nil assertion.root.at_xpath("saml:AttributeStatement", NS)
    end

    def test_attribute_statement_with_single_value
      attributes = { "email" => "user@example.com" }
      assertion = Assertion.new(attributes: attributes).document
      as = assertion.root.at_xpath("saml:AttributeStatement", NS)
      assert_equal "AttributeStatement", as.name
      assert_equal "saml", as.namespace.prefix
    end

    def test_attribute_name_and_format
      attributes = { "email" => "user@example.com" }
      assertion = Assertion.new(attributes: attributes).document
      path = "saml:AttributeStatement/saml:Attribute"
      attr = assertion.root.at_xpath(path, NS)

      assert_equal "Attribute", attr.name
      assert_equal "saml", attr.namespace.prefix
      assert_equal "email", attr["Name"]
      assert_equal ATTR_NAME_FORMAT, attr["NameFormat"]
    end

    def test_attribute_single_value
      attributes = { "email" => "user@example.com" }
      assertion = Assertion.new(attributes: attributes).document
      path = "saml:AttributeStatement/saml:Attribute"
      attr = assertion.root.at_xpath(path, NS)
      value = attr.at_xpath("saml:AttributeValue", NS)

      assert_equal "AttributeValue", value.name
      assert_equal "saml", value.namespace.prefix
      assert_equal "user@example.com", value.text
    end

    def test_attribute_multi_value
      attributes = { "groups" => ["admin", "users", "developers"] }
      assertion = Assertion.new(attributes: attributes).document
      path = "saml:AttributeStatement/saml:Attribute"
      attr = assertion.root.at_xpath(path, NS)
      values = attr.xpath("saml:AttributeValue", NS)

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
      as = assertion.root.at_xpath("saml:AttributeStatement", NS)
      attrs = as.xpath("saml:Attribute", NS)
      assert_equal 3, attrs.size

      email_attr = attrs.find { |a| a["Name"] == "email" }
      email_value = email_attr.at_xpath("saml:AttributeValue", NS).text
      assert_equal "user@example.com", email_value

      name_attr = attrs.find { |a| a["Name"] == "name" }
      name_value = name_attr.at_xpath("saml:AttributeValue", NS).text
      assert_equal "Test User", name_value

      groups_attr = attrs.find { |a| a["Name"] == "groups" }
      group_values = groups_attr.xpath("saml:AttributeValue", NS)
      assert_equal 2, group_values.size
      assert_equal "admin", group_values[0].text
      assert_equal "users", group_values[1].text
    end
  end
end
