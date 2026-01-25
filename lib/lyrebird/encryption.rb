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
      end
    end
  end
end
