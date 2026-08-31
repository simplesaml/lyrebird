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
      @not_before = (not_before || @issue_instant).to_time.getutc
      @not_on_or_after = [@issue_instant, @not_before].max + valid_for
      @audience = audience
      @authn_context = authn_context
      @attributes = attributes
    end

    def document
      @document ||= Nokogiri::XML::Builder.new { |xml| root(xml) }.doc
    end

    private

    def root(xml)
      attrs = {
        "xmlns:saml" => SAML_ASSERTION_NS,
        ID: ID.generate,
        Version: "2.0",
        IssueInstant: @issue_instant.iso8601
      }

      xml["saml"].Assertion(attrs) do
        xml["saml"].Issuer(@issuer.to_s)
        subject(xml)
        conditions(xml)
        authn_statement(xml)
        attribute_statement(xml) if @attributes.any?
      end
    end

    def subject(xml)
      xml["saml"].Subject do
        xml["saml"].NameID(@name_id.to_s, Format: @name_id_format)
        subject_confirmation(xml)
      end
    end

    def subject_confirmation(xml)
      attrs = {
        NotOnOrAfter: @not_on_or_after.iso8601,
        Recipient: @recipient,
        InResponseTo: @in_response_to
      }.compact

      xml["saml"].SubjectConfirmation(Method: CM_BEARER) do
        xml["saml"].SubjectConfirmationData(attrs)
      end
    end

    def conditions(xml)
      attrs = {
        NotBefore: @not_before.iso8601,
        NotOnOrAfter: @not_on_or_after.iso8601
      }

      xml["saml"].Conditions(attrs) do
        xml["saml"].AudienceRestriction do
          xml["saml"].Audience(@audience.to_s)
        end
      end
    end

    def authn_statement(xml)
      attrs = {
        AuthnInstant: @issue_instant.iso8601,
        SessionIndex: ID.generate
      }

      xml["saml"].AuthnStatement(attrs) do
        xml["saml"].AuthnContext do
          xml["saml"].AuthnContextClassRef(@authn_context.to_s)
        end
      end
    end

    def attribute_statement(xml)
      xml["saml"].AttributeStatement do
        @attributes.each do |name, values|
          list = values.is_a?(Enumerable) ? values.to_a : [values].compact

          xml["saml"].Attribute(Name: name, NameFormat: ATTR_NAME_FORMAT) do
            list.each { |value| xml["saml"].AttributeValue(value.to_s) }
          end
        end
      end
    end
  end
end
