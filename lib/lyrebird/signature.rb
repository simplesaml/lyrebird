# frozen_string_literal: true

module Lyrebird
  class Signature
    C14N_EXCLUSIVE = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0

    def initialize(element, certificate)
      @element = element
      @certificate = certificate
    end

    def sign!
      ns = { "saml" => SAML_ASSERTION_NS, "ds" => XMLDSIG_NS }
      @element.at_xpath("ds:Signature", ns)&.remove
      signature = build_signature
      issuer = @element.at_xpath("saml:Issuer", ns)
      issuer.add_next_sibling(signature)
      populate_signature_value(signature)
      self
    end

    private

    def build_signature
      Nokogiri::XML::Builder.new do |xml|
        xml["ds"].Signature("xmlns:ds" => XMLDSIG_NS) do
          signed_info(xml)
          xml["ds"].SignatureValue
          key_info(xml)
        end
      end.doc.root
    end

    def signed_info(xml)
      xml["ds"].SignedInfo do
        xml["ds"].CanonicalizationMethod(Algorithm: EXC_C14N)
        xml["ds"].SignatureMethod(Algorithm: RSA_SHA256)
        reference(xml)
      end
    end

    def reference(xml)
      xml["ds"].Reference(URI: "##{@element["ID"]}") do
        xml["ds"].Transforms do
          xml["ds"].Transform(Algorithm: ENVELOPED_SIG)
          xml["ds"].Transform(Algorithm: EXC_C14N)
        end

        xml["ds"].DigestMethod(Algorithm: SHA256_DIGEST)
        xml["ds"].DigestValue(compute_digest)
      end
    end

    def key_info(xml)
      xml["ds"].KeyInfo do
        xml["ds"].X509Data do
          xml["ds"].X509Certificate(@certificate.base64)
        end
      end
    end

    def compute_digest
      canonical = @element.canonicalize(C14N_EXCLUSIVE)
      digest = OpenSSL::Digest.new("SHA256").digest(canonical)
      [digest].pack("m0")
    end

    def populate_signature_value(signature)
      ns = { "ds" => XMLDSIG_NS }
      signed_info = signature.at_xpath("ds:SignedInfo", ns)
      canonical = signed_info.canonicalize(C14N_EXCLUSIVE)
      sig = @certificate.key.sign(OpenSSL::Digest.new("SHA256"), canonical)
      value = signature.at_xpath("ds:SignatureValue", ns)
      value.content = [sig].pack("m0")
    end
  end
end
