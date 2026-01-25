# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class SignatureTest < Minitest::Test
    def setup
      @certificate = Certificate.generate
      @assertion = Assertion.new.document
      @element = @assertion.root
      @signature = Signature.new(@element, certificate: @certificate)
      @reference = @signature.reference
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
  end
end
