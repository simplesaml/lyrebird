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
      element = @assertion.document.root

      if @encrypt_with
        Signature.new(element, @sign_with).sign! if @sign_with
        Encryption.new(element, @encrypt_with).encrypt
      else
        element
      end
    end

    def sign_assertion(doc)
      ns = { "saml" => SAML_ASSERTION_NS }
      assertion = doc.root.at_xpath("saml:Assertion", ns)
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
