# frozen_string_literal: true

module Lyrebird
  class Response
    def self.build(**kwargs)
      config = OpenStruct.new(kwargs)

      config.define_singleton_method(:attributes) do |&block|
        self.attributes = OpenStruct.new.tap(&block).to_h
      end

      yield config if block_given?
      new(**config.to_h)
    end

    def initialize(
      issuer: DEFAULTS.issuer,
      destination: DEFAULTS.recipient,
      in_response_to: DEFAULTS.in_response_to,
      sign_with: nil,
      encrypt_with: nil,
      **assertion_options
    )
      @issuer = issuer
      @destination = destination
      @in_response_to = in_response_to
      @sign_with = sign_with
      @encrypt_with = encrypt_with

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
        r.add_attribute("Destination", @destination) if @destination
        r.add_attribute("InResponseTo", @in_response_to) if @in_response_to
        r.add_element("saml:Issuer").text = @issuer
        r.add_element(status)
        r.add_element(assertion_element)
        Signature.new(r, @sign_with).sign! if @sign_with
      end
    end

    def assertion_element
      element = @assertion.document.root
      Signature.new(element, @sign_with).sign! if @sign_with
      return element unless @encrypt_with
      Encryption.new(element, @encrypt_with).encrypt
    end

    def status
      REXML::Element.new("samlp:Status").tap do |s|
        sc = s.add_element("samlp:StatusCode")
        sc.add_attribute("Value", STATUS_SUCCESS)
      end
    end
  end
end
