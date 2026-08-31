# frozen_string_literal: true

module Lyrebird
  class Response
    class Config < Options
      def attributes(&block)
        current = self[:attributes] || {}
        return current unless block

        fresh = Options.new.tap(&block).to_h
        self[:attributes] = current.transform_keys(&:to_sym).merge(fresh)
      end
    end

    def self.build(**kwargs)
      config = Config.new(kwargs)
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
      [to_xml].pack("m0")
    end

    def to_xml
      document.to_xml(save_with: 0)
    end

    def document
      @document ||= build_response.doc.tap do |doc|
        Signature.new(doc.root, @sign_with).sign! if @sign_with
      end
    end

    private

    def build_response
      attrs = {
        "xmlns:samlp" => SAML_PROTOCOL_NS,
        "xmlns:saml" => SAML_ASSERTION_NS,
        ID: ID.generate,
        Version: "2.0",
        IssueInstant: Time.now.utc.iso8601,
        Destination: @destination,
        InResponseTo: @in_response_to
      }.compact

      Nokogiri::XML::Builder.new do |xml|
        xml["samlp"].Response(attrs) do
          xml["saml"].Issuer(@issuer.to_s)

          xml["samlp"].Status do
            xml["samlp"].StatusCode(Value: STATUS_SUCCESS)
          end

          xml.parent << build_assertion_element
        end
      end
    end

    def build_assertion_element
      element = @assertion.document.root
      Signature.new(element, @sign_with).sign! if @sign_with
      element = Encryption.new(element, @encrypt_with).encrypt if @encrypt_with
      element
    end
  end
end
