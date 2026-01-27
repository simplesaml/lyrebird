# frozen_string_literal: true

module Lyrebird
  class Assertion
    def initialize(
      issuer: DEFAULTS.issuer,
      name_id: DEFAULTS.name_id,
      name_id_format: DEFAULTS.name_id_format,
      recipient: DEFAULTS.recipient,
      in_response_to: DEFAULTS.in_response_to,
      not_before: nil,
      valid_for: DEFAULTS.valid_for,
      audience: DEFAULTS.audience,
      authn_context: DEFAULTS.authn_context,
      attributes: DEFAULTS.attributes
    )
      @issue_instant = Time.now.utc
      @issuer = issuer
      @name_id = name_id
      @name_id_format = name_id_format
      @recipient = recipient
      @in_response_to = in_response_to
      @not_before = not_before || @issue_instant
      @not_on_or_after = @issue_instant + valid_for
      @audience = audience
      @authn_context = authn_context
      @attributes = attributes
    end

    def document
      REXML::Document.new.tap do |d|
        d.add_element(root)
      end
    end

    private

    def root
      REXML::Element.new("saml:Assertion").tap do |r|
        r.add_namespace("saml", SAML_ASSERTION_NS)
        r.add_attribute("ID", ID.generate)
        r.add_attribute("Version", "2.0")
        r.add_attribute("IssueInstant", @issue_instant.iso8601)
        r.add_element("saml:Issuer").text = @issuer
        r.add_element(subject)
        r.add_element(conditions)
        r.add_element(authn_statement)
        r.add_element(attribute_statement) if @attributes.any?
      end
    end

    def subject
      REXML::Element.new("saml:Subject").tap do |s|
        name_id = s.add_element("saml:NameID")
        name_id.add_attribute("Format", @name_id_format)
        name_id.text = @name_id
        s.add_element(subject_confirmation)
      end
    end

    def subject_confirmation
      REXML::Element.new("saml:SubjectConfirmation").tap do |sc|
        sc.add_attribute("Method", CM_BEARER)
        data = sc.add_element("saml:SubjectConfirmationData")
        data.add_attribute("NotOnOrAfter", @not_on_or_after.iso8601)
        data.add_attribute("Recipient", @recipient)
        data.add_attribute("InResponseTo", @in_response_to) if @in_response_to
      end
    end

    def conditions
      REXML::Element.new("saml:Conditions").tap do |c|
        c.add_attribute("NotBefore", @not_before.iso8601)
        c.add_attribute("NotOnOrAfter", @not_on_or_after.iso8601)
        ar = c.add_element("saml:AudienceRestriction")
        ar.add_element("saml:Audience").text = @audience
      end
    end

    def authn_statement
      REXML::Element.new("saml:AuthnStatement").tap do |as|
        as.add_attribute("AuthnInstant", @issue_instant.iso8601)
        as.add_attribute("SessionIndex", ID.generate)
        ac = as.add_element("saml:AuthnContext")
        cr = ac.add_element("saml:AuthnContextClassRef")
        cr.text = @authn_context
      end
    end

    def attribute_statement
      REXML::Element.new("saml:AttributeStatement").tap do |as|
        @attributes.each do |name, values|
          a = as.add_element("saml:Attribute")
          a.add_attribute("Name", name)
          a.add_attribute("NameFormat", ATTR_NAME_FORMAT)

          Array(values).each do |value|
            a.add_element("saml:AttributeValue").text = value
          end
        end
      end
    end
  end
end
