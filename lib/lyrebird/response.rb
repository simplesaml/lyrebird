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
      Nokogiri::XML::Document.new.tap do |doc|
        doc.root = root(doc)
      end
    end

    private

    def root(doc)
      doc.create_element("Response").tap do |r|
        samlp = r.add_namespace_definition("samlp", SAML_PROTOCOL_NS)
        saml = r.add_namespace_definition("saml", SAML_ASSERTION_NS)

        r.namespace = samlp
        r["ID"] = ID.generate
        r["Version"] = "2.0"
        r["IssueInstant"] = Time.now.utc.iso8601
        r["Destination"] = @destination if @destination
        r["InResponseTo"] = @in_response_to if @in_response_to

        issuer = doc.create_element("Issuer").tap do |i|
          i.namespace = saml
          i.content = @issuer
        end

        r.add_child(issuer)
        r.add_child(status(doc, samlp))
        r.add_child(assertion_element)
        Signature.new(r, @sign_with).sign! if @sign_with
      end
    end

    def assertion_element
      element = @assertion.document.root
      Signature.new(element, @sign_with).sign! if @sign_with
      return element unless @encrypt_with

      Encryption.new(element, @encrypt_with).encrypt
    end

    def status(doc, ns)
      doc.create_element("Status").tap do |s|
        s.namespace = ns

        status_code = doc.create_element("StatusCode").tap do |sc|
          sc.namespace = ns
          sc["Value"] = STATUS_SUCCESS
        end

        s.add_child(status_code)
      end
    end
  end
end
