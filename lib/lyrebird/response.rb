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
      Base64.strict_encode64(document.to_xml(save_with: 0))
    end

    def document
      @document ||= Nokogiri::XML::Document.new.tap do |doc|
        doc.root = build_response(doc)
        sign_assertion(doc) if @sign_with && !@encrypt_with
        sign_response(doc) if @sign_with
      end
    end

    private

    def build_response(doc)
      doc.create_element("Response").tap do |r|
        @samlp = r.add_namespace_definition("samlp", SAML_PROTOCOL_NS)
        @saml = r.add_namespace_definition("saml", SAML_ASSERTION_NS)

        r.namespace = @samlp
        r["ID"] = ID.generate
        r["Version"] = "2.0"
        r["IssueInstant"] = Time.now.utc.iso8601
        r["Destination"] = @destination if @destination
        r["InResponseTo"] = @in_response_to if @in_response_to

        r.add_child(doc.create_element("Issuer")).tap do |i|
          i.namespace = @saml
          i.content = @issuer
        end

        r.add_child(build_status(doc))
        r.add_child(build_assertion_element)
      end
    end

    def build_assertion_element
      assertion_doc = @assertion.document
      element = assertion_doc.root

      if @encrypt_with
        Signature.new(element, @sign_with).sign! if @sign_with
        Encryption.new(element, @encrypt_with).encrypt
      else
        element
      end
    end

    def sign_assertion(doc)
      ns = { "saml" => SAML_ASSERTION_NS }
      assertion = doc.at_xpath("//saml:Assertion", ns)
      Signature.new(assertion, @sign_with).sign!
    end

    def sign_response(doc)
      Signature.new(doc.root, @sign_with).sign!
    end

    def build_status(doc)
      doc.create_element("Status").tap do |s|
        s.namespace = @samlp

        s.add_child(doc.create_element("StatusCode")).tap do |sc|
          sc.namespace = @samlp
          sc["Value"] = STATUS_SUCCESS
        end
      end
    end
  end
end
