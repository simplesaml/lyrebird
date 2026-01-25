# frozen_string_literal: true

module Lyrebird
  class Signature
    def initialize(element, certificate:)
      @element = element
      @certificate = certificate
      @element_id = @element.attributes["ID"]
    end

    def sign!
    end

    def signed_info
      REXML::Element.new("ds:SignedInfo").tap do |si|
        cm = si.add_element("ds:CanonicalizationMethod")
        cm.add_attribute("Algorithm", EXC_C14N)
        sm = si.add_element("ds:SignatureMethod")
        sm.add_attribute("Algorithm", RSA_SHA256)
        si.add_element(reference)
      end
    end

    private

    def reference
      REXML::Element.new("ds:Reference").tap do |ref|
        ref.add_attribute("URI", "##{@element_id}")
        ref.add_element(transforms)
        dm = ref.add_element("ds:DigestMethod")
        dm.add_attribute("Algorithm", SHA256_DIGEST)
        ref.add_element("ds:DigestValue").text = compute_digest(@element)
      end
    end

    def transforms
      REXML::Element.new("ds:Transforms").tap do |t|
        enveloped = t.add_element("ds:Transform")
        enveloped.add_attribute("Algorithm", ENVELOPED_SIG)
        c14n = t.add_element("ds:Transform")
        c14n.add_attribute("Algorithm", EXC_C14N)
      end
    end

    def compute_digest(element)
      digest = OpenSSL::Digest::SHA256.digest(element.to_s)
      Base64.strict_encode64(digest)
    end
  end
end
