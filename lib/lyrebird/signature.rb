# frozen_string_literal: true

module Lyrebird
  class Signature
    def initialize(element, certificate:)
      @element = element
      @certificate = certificate
      @element_id = @element.attributes["ID"]
    end

    def sign!
      issuer = @element.elements["saml:Issuer"]
      @element.insert_after(issuer, signature_element)
    end

    private

    def signature_element
      REXML::Element.new("ds:Signature").tap do |sig|
        sig.add_namespace("ds", XMLDSIG_NS)
        sig.add_element(signed_info)
        sig.add_element(signature_value)
        sig.add_element(key_info)
      end
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

    def signature_value
      REXML::Element.new("ds:SignatureValue").tap do |sv|
        sig = @certificate.private_key.sign("SHA256", signed_info.to_s)
        sv.text = Base64.strict_encode64(sig)
      end
    end

    def key_info
      REXML::Element.new("ds:KeyInfo").tap do |ki|
        x = ki.add_element("ds:X509Data")
        x.add_element("ds:X509Certificate").text = @certificate.base64
      end
    end

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
