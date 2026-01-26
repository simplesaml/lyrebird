# frozen_string_literal: true

module Lyrebird
  class Response
    def self.build(**kwargs)
      config = OpenStruct.new(kwargs)
      yield config if block_given?
      new(**config.to_h)
    end

    def initialize(
      issuer: DEFAULTS.issuer,
      destination: DEFAULTS.recipient,
      in_response_to: DEFAULTS.in_response_to,
      idp_certificate: nil,
      sign_assertion: false,
      sign_response: false,
      encrypt_assertion: false,
      sp_certificate: nil,
      **assertion_options
    )
      @issuer = issuer
      @destination = destination
      @in_response_to = in_response_to
      @idp_certificate = idp_certificate
      @sign_assertion = sign_assertion
      @sign_response = sign_response
      @encrypt_assertion = encrypt_assertion
      @sp_certificate = sp_certificate

      @assertion = Assertion.new(
        issuer: issuer,
        in_response_to: in_response_to,
        **assertion_options
      )
    end

    def mimic
      Base64.strict_encode64(document.to_s)
    end

    def document
      REXML::Document.new.tap do |d|
        d.add_element(root)
      end
    end

    private

    def root
      REXML::Element.new("samlp:Response").tap do |r|
        r.add_namespace("samlp", SAML_PROTOCOL_NS)
        r.add_namespace("saml", SAML_ASSERTION_NS)
        r.add_attribute("ID", ID.generate)
        r.add_attribute("Version", "2.0")
        r.add_attribute("IssueInstant", Time.now.utc.iso8601)
        r.add_attribute("Destination", @destination)
        r.add_attribute("InResponseTo", @in_response_to)
        r.add_element("saml:Issuer").text = @issuer
        r.add_element(status)
        r.add_element(assertion_element)
        Signature.new(r, @idp_certificate).sign! if @sign_response
      end
    end

    def assertion_element
      element = @assertion.document.root
      Signature.new(element, @idp_certificate).sign! if @sign_assertion
      return element unless @encrypt_assertion
      Encryption.new(element, @sp_certificate).encrypt
    end

    def status
      REXML::Element.new("samlp:Status").tap do |s|
        sc = s.add_element("samlp:StatusCode")
        sc.add_attribute("Value", STATUS_SUCCESS)
      end
    end
  end
end
