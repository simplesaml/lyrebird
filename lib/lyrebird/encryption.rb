# frozen_string_literal: true

module Lyrebird
  class Encryption
    def initialize(element, certificate)
      @element = element
      @certificate = certificate
    end

    def encrypt!
      encrypted_assertion
    end

    private

    def encrypted_assertion
      REXML::Element.new("saml:EncryptedAssertion").tap do |ea|
        ea.add_namespace("saml", SAML_ASSERTION_NS)
        ea.add_element(encrypted_data)
      end
    end

    def encrypted_data
      REXML::Element.new("xenc:EncryptedData").tap do |ed|
        ed.add_namespace("xenc", XMLENC_NS)
        ed.add_attribute("Type", "#{XMLENC_NS}Element")
        em = ed.add_element("xenc:EncryptionMethod")
        em.add_attribute("Algorithm", AES256_CBC)
      end
    end
  end
end
