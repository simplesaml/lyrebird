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

    def reference
      REXML::Element.new("ds:Reference").tap do |ref|
        ref.add_attribute("URI", "##{@element_id}")
        ref.add_element(transforms)
        dm = ref.add_element("ds:DigestMethod")
        dm.add_attribute("Algorithm", SHA256_DIGEST)
        ref.add_element("ds:DigestValue").text = compute_digest(@element)
      end
    end

    private

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
