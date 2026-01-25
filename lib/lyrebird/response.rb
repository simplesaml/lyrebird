# frozen_string_literal: true

module Lyrebird
  class Response
    def initialize(
      issuer: DEFAULTS.issuer,
      destination: DEFAULTS.recipient,
      in_response_to: DEFAULTS.in_response_to,
      sign_assertion: false,
      sign_response: false,
      **assertion_options
    )
      @id = ID.generate
      @issue_instant = Time.now.utc
      @issuer = issuer
      @destination = destination
      @in_response_to = in_response_to
      @sign_assertion = sign_assertion
      @sign_response = sign_response

      @assertion = Assertion.new(
        issuer: issuer,
        in_response_to: in_response_to,
        **assertion_options
      )
    end

    def mimic
      REXML::Document.new.tap do |d|
        d.add_element(root)
      end
    end

    private

    def root
      REXML::Element.new("samlp:Response").tap do |r|
        r.add_namespace("samlp", SAML_PROTOCOL_NS)
        r.add_namespace("saml", SAML_ASSERTION_NS)
        r.add_attribute("ID", @id)
        r.add_attribute("Version", "2.0")
        r.add_attribute("IssueInstant", @issue_instant.iso8601)
        r.add_attribute("Destination", @destination)
        r.add_attribute("InResponseTo", @in_response_to)
        r.add_element("saml:Issuer").text = @issuer
        r.add_element(status)
      end
    end

    def status
      REXML::Element.new("samlp:Status").tap do |s|
        sc = s.add_element("samlp:StatusCode")
        sc.add_attribute("Value", STATUS_SUCCESS)
      end
    end
  end
end
