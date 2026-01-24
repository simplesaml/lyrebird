# frozen_string_literal: true

module Lyrebird
  class Assertion
    def initialize(
      issuer: DEFAULTS.issuer,
      name_id: DEFAULTS.name_id,
      name_id_format: DEFAULTS.name_id_format
    )
      @id = ID.generate
      @issue_instant = Time.now.utc
      @issuer = issuer
      @name_id = name_id
      @name_id_format = name_id_format
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
      end
    end

    def subject
      REXML::Element.new("saml:Subject").tap do |s|
        name_id = s.add_element("saml:NameID")
        name_id.add_attribute("Format", @name_id_format)
        name_id.text = @name_id
      end
    end
  end
end
