# frozen_string_literal: true

module Lyrebird
  class Assertion
    def initialize
      @id = ID.generate
      @issue_instant = Time.now.utc
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
      end
    end
  end
end
