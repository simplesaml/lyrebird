# frozen_string_literal: true

module Lyrebird
  class Assertion
    def initialize(
      issuer: DEFAULTS.issuer,
      name_id: DEFAULTS.name_id,
      name_id_format: DEFAULTS.name_id_format,
      recipient: DEFAULTS.recipient,
      in_response_to: DEFAULTS.in_response_to,
      valid_for: DEFAULTS.valid_for
    )
      @id = ID.generate
      @issue_instant = Time.now.utc
      @issuer = issuer
      @name_id = name_id
      @name_id_format = name_id_format
      @recipient = recipient
      @in_response_to = in_response_to
      @not_on_or_after = @issue_instant + valid_for
    end

    def mimic
      REXML::Document.new.tap do |d|
        d.add_element(root)
      end
    end

    private

    def root
      REXML::Element.new("saml:Assertion").tap do |r|
        r.add_namespace("saml", SAML_ASSERTION_NS)
        r.add_attribute("ID", @id)
        r.add_attribute("Version", "2.0")
        r.add_attribute("IssueInstant", @issue_instant.iso8601)
        r.add_element("saml:Issuer").text = @issuer
        r.add_element(subject)
        r.add_element(conditions)
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
        data.add_attribute("InResponseTo", @in_response_to)
      end
    end

    def conditions
      REXML::Element.new("saml:Conditions").tap do |c|
        c.add_attribute("NotBefore", @issue_instant.iso8601)
        c.add_attribute("NotOnOrAfter", @not_on_or_after.iso8601)
      end
    end
  end
end
