# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class SignatureTest < Minitest::Test
    NS = { "ds" => XMLDSIG_NS, "saml" => SAML_ASSERTION_NS }.freeze

    def setup
      @certificate = Certificate.default
      @assertion = Assertion.new.document
      @element = @assertion.root
      Signature.new(@element, @certificate).sign!
      @signature = @element.at_xpath("ds:Signature", NS)
      @signed_info = @signature.at_xpath("ds:SignedInfo", NS)
      @reference = @signed_info.at_xpath("ds:Reference", NS)
    end

    def test_sign_inserts_after_issuer
      children = @element.element_children
      issuer_index = children.index { |e| e.name == "Issuer" }
      signature_index = children.index { |e| e.name == "Signature" }
      assert_equal issuer_index + 1, signature_index
    end

    def test_signature_element
      assert_equal "Signature", @signature.name
      assert_equal "ds", @signature.namespace.prefix
      assert_equal XMLDSIG_NS, @signature.namespace.href
    end

    def test_signature_element_children
      children = @signature.element_children
      assert_equal 3, children.size
      assert_equal "SignedInfo", children[0].name
      assert_equal "SignatureValue", children[1].name
      assert_equal "KeyInfo", children[2].name
    end

    def test_signed_info_element
      assert_equal "SignedInfo", @signed_info.name
      assert_equal "ds", @signed_info.namespace.prefix
    end

    def test_canonicalization_method
      cm = @signed_info.at_xpath("ds:CanonicalizationMethod", NS)
      assert_equal "CanonicalizationMethod", cm.name
      assert_equal EXC_C14N, cm["Algorithm"]
    end

    def test_signature_method
      sm = @signed_info.at_xpath("ds:SignatureMethod", NS)
      assert_equal "SignatureMethod", sm.name
      assert_equal RSA_SHA256, sm["Algorithm"]
    end

    def test_reference_element
      assert_equal "Reference", @reference.name
      assert_equal "ds", @reference.namespace.prefix
    end

    def test_reference_uri
      assert_equal "##{@element["ID"]}", @reference["URI"]
    end

    def test_transforms_element
      transforms = @reference.at_xpath("ds:Transforms", NS)
      assert_equal "Transforms", transforms.name
      assert_equal "ds", transforms.namespace.prefix
    end

    def test_enveloped_signature_transform
      transforms = @reference.xpath("ds:Transforms/ds:Transform", NS)
      assert_equal ENVELOPED_SIG, transforms[0]["Algorithm"]
    end

    def test_c14n_transform
      transforms = @reference.xpath("ds:Transforms/ds:Transform", NS)
      assert_equal EXC_C14N, transforms[1]["Algorithm"]
    end

    def test_digest_method_element
      digest_method = @reference.at_xpath("ds:DigestMethod", NS)
      assert_equal "DigestMethod", digest_method.name
      assert_equal "ds", digest_method.namespace.prefix
    end

    def test_digest_method_algorithm
      digest_method = @reference.at_xpath("ds:DigestMethod", NS)
      assert_equal SHA256_DIGEST, digest_method["Algorithm"]
    end

    def test_digest_value_element
      digest_value = @reference.at_xpath("ds:DigestValue", NS)
      assert_equal "DigestValue", digest_value.name
      assert_equal "ds", digest_value.namespace.prefix
    end

    def test_digest_value_is_base64
      digest_value = @reference.at_xpath("ds:DigestValue", NS)
      decoded = digest_value.text.unpack1("m0")
      assert_equal 32, decoded.bytesize
    end

    def test_signature_value_element
      sv = @signature.at_xpath("ds:SignatureValue", NS)
      assert_equal "SignatureValue", sv.name
      assert_equal "ds", sv.namespace.prefix
    end

    def test_signature_value_is_base64
      sv = @signature.at_xpath("ds:SignatureValue", NS)
      decoded = sv.text.unpack1("m0")
      assert_equal 256, decoded.bytesize
    end

    def test_key_info_element
      ki = @signature.at_xpath("ds:KeyInfo", NS)
      assert_equal "KeyInfo", ki.name
      assert_equal "ds", ki.namespace.prefix
    end

    def test_x509_data_element
      x509_data = @signature.at_xpath("ds:KeyInfo/ds:X509Data", NS)
      assert_equal "X509Data", x509_data.name
      assert_equal "ds", x509_data.namespace.prefix
    end

    def test_x509_certificate_element
      xpath = "ds:KeyInfo/ds:X509Data/ds:X509Certificate"
      cert = @signature.at_xpath(xpath, NS)
      assert_equal "X509Certificate", cert.name
      assert_equal "ds", cert.namespace.prefix
      assert_equal @certificate.base64, cert.text
    end

    def test_sign_twice_leaves_one_signature
      element = Assertion.new.document.root
      Signature.new(element, @certificate).sign!
      Signature.new(element, @certificate).sign!
      assert_equal 1, element.xpath("ds:Signature", NS).size
    end

    def test_sign_twice_uses_latest_certificate
      other = Certificate.build
      element = Assertion.new.document.root
      Signature.new(element, @certificate).sign!
      Signature.new(element, other).sign!
      xpath = "ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate"
      assert_equal other.base64, element.at_xpath(xpath, NS).text
    end

    def test_sign_twice_produces_verifiable_signature
      element = Assertion.new.document.root
      Signature.new(element, @certificate).sign!
      Signature.new(element, @certificate).sign!

      signature = element.at_xpath("ds:Signature", NS)
      xpath = "ds:SignedInfo/ds:Reference/ds:DigestValue"
      expected = signature.at_xpath(xpath, NS).text.unpack1("m0")
      signature.remove
      canonical = element.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)

      assert_equal expected, OpenSSL::Digest::SHA256.digest(canonical)
    end

    def test_sign_keeps_nested_signature
      response = Response.new(sign_with: @certificate).document.root
      xpath = "saml:Assertion/ds:Signature"

      refute_nil response.at_xpath(xpath, NS)
      assert_equal 1, response.xpath("ds:Signature", NS).size
    end

    def test_digest_verifies
      signature = @element.at_xpath("ds:Signature", NS)
      reference = signature.at_xpath("ds:SignedInfo/ds:Reference", NS)

      signature.remove
      c14n = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
      canonical = @element.canonicalize(c14n)
      computed = OpenSSL::Digest::SHA256.digest(canonical)

      digest_value = reference.at_xpath("ds:DigestValue", NS)
      expected = digest_value.text.unpack1("m0")
      assert_equal expected, computed
    end

    def test_signature_verifies
      c14n = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
      canonical = @signed_info.canonicalize(c14n)

      sig_value = @signature.at_xpath("ds:SignatureValue", NS)
      signature_bytes = sig_value.text.unpack1("m0")

      public_key = @certificate.x509.public_key
      verified = public_key.verify("SHA256", signature_bytes, canonical)
      assert verified
    end
  end
end
