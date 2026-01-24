# frozen_string_literal: true

module Lyrebird
  class Assertion
    def initialize(issuer: DEFAULTS.issuer)
      @id = ID.generate
      @issue_instant = Time.now.utc
      @issuer = issuer
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
      end
    end
  end
end
