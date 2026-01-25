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
  end
end
