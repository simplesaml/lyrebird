# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class SignatureTest < Minitest::Test
    def setup
      @certificate = Certificate.build
      @assertion = Assertion.new.document
      @element = @assertion.root
      Signature.new(@element, @certificate).sign!
      @signature = @element.elements["ds:Signature"]
      @signed_info = @signature.elements["ds:SignedInfo"]
      @reference = @signed_info.elements["ds:Reference"]
    end

    def test_sign_inserts_after_issuer
      children = @element.elements.to_a
      issuer_index = children.index { |e| e.name == "Issuer" }
      signature_index = children.index { |e| e.name == "Signature" }
      assert_equal issuer_index + 1, signature_index
    end

    def test_signature_element
      assert_equal "Signature", @signature.name
      assert_equal "ds", @signature.prefix
      assert_equal XMLDSIG_NS, @signature.namespace
    end

    def test_signature_element_children
      children = @signature.elements.to_a
      assert_equal 3, children.size
      assert_equal "SignedInfo", children[0].name
      assert_equal "SignatureValue", children[1].name
      assert_equal "KeyInfo", children[2].name
    end

    def test_signed_info_element
      assert_equal "SignedInfo", @signed_info.name
      assert_equal "ds", @signed_info.prefix
    end

    def test_canonicalization_method
      cm = @signed_info.elements["ds:CanonicalizationMethod"]
      assert_equal "CanonicalizationMethod", cm.name
      assert_equal EXC_C14N, cm.attributes["Algorithm"]
    end

    def test_signature_method
      sm = @signed_info.elements["ds:SignatureMethod"]
      assert_equal "SignatureMethod", sm.name
      assert_equal RSA_SHA256, sm.attributes["Algorithm"]
    end

    def test_reference_element
      assert_equal "Reference", @reference.name
      assert_equal "ds", @reference.prefix
    end

    def test_reference_uri
      element_id = @element.attributes["ID"]
      assert_equal "##{element_id}", @reference.attributes["URI"]
    end

    def test_transforms_element
      transforms = @reference.elements["ds:Transforms"]
      assert_equal "Transforms", transforms.name
      assert_equal "ds", transforms.prefix
    end

    def test_enveloped_signature_transform
      transforms = @reference.elements["ds:Transforms"]
      transform = transforms.elements.to_a("ds:Transform")[0]
      assert_equal ENVELOPED_SIG, transform.attributes["Algorithm"]
    end

    def test_c14n_transform
      transforms = @reference.elements["ds:Transforms"]
      transform = transforms.elements.to_a("ds:Transform")[1]
      assert_equal EXC_C14N, transform.attributes["Algorithm"]
    end

    def test_digest_method_element
      digest_method = @reference.elements["ds:DigestMethod"]
      assert_equal "DigestMethod", digest_method.name
      assert_equal "ds", digest_method.prefix
    end

    def test_digest_method_algorithm
      digest_method = @reference.elements["ds:DigestMethod"]
      assert_equal SHA256_DIGEST, digest_method.attributes["Algorithm"]
    end

    def test_digest_value_element
      digest_value = @reference.elements["ds:DigestValue"]
      assert_equal "DigestValue", digest_value.name
      assert_equal "ds", digest_value.prefix
    end

    def test_digest_value_is_base64
      digest_value = @reference.elements["ds:DigestValue"]
      decoded = Base64.strict_decode64(digest_value.text)
      assert_equal 32, decoded.bytesize
    end

    def test_signature_value_element
      sv = @signature.elements["ds:SignatureValue"]
      assert_equal "SignatureValue", sv.name
      assert_equal "ds", sv.prefix
    end

    def test_signature_value_is_base64
      sv = @signature.elements["ds:SignatureValue"]
      decoded = Base64.strict_decode64(sv.text)
      assert_equal 256, decoded.bytesize
    end

    def test_key_info_element
      ki = @signature.elements["ds:KeyInfo"]
      assert_equal "KeyInfo", ki.name
      assert_equal "ds", ki.prefix
    end

    def test_x509_data_element
      x509_data = @signature.elements["ds:KeyInfo/ds:X509Data"]
      assert_equal "X509Data", x509_data.name
      assert_equal "ds", x509_data.prefix
    end

    def test_x509_certificate_element
      cert = @signature.elements["ds:KeyInfo/ds:X509Data/ds:X509Certificate"]
      assert_equal "X509Certificate", cert.name
      assert_equal "ds", cert.prefix
      assert_equal @certificate.base64, cert.text
    end
  end
end
