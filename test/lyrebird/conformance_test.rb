# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class ConformanceTest < Minitest::Test
    NS = { "saml" => SAML_ASSERTION_NS }.freeze
    XSD = File.expand_path("../schemas/saml-schema-protocol-2.0.xsd", __dir__)

    def setup
      doc = Nokogiri::XML(File.read(XSD), XSD)
      @schema = Nokogiri::XML::Schema.from_document(doc)
    end

    def test_default_response
      assert_valid Response.new
    end

    def test_signed_response
      assert_valid Response.new(sign_with: Certificate.default)
    end

    def test_encrypted_response
      assert_valid Response.new(encrypt_with: Certificate.default)
    end

    def test_signed_and_encrypted_response
      cert = Certificate.default
      assert_valid Response.new(sign_with: cert, encrypt_with: cert)
    end

    def test_idp_initiated_response
      assert_valid Response.new(in_response_to: nil, destination: nil)
    end

    def test_response_without_attributes
      assert_valid Response.new(attributes: {})
    end

    def test_response_with_multi_value_attributes
      assert_valid Response.new(attributes: { groups: %w[a b c] })
    end

    def test_schema_rejects_out_of_order_elements
      doc = parse(Response.new)
      assertion = doc.at_xpath("//saml:Assertion", NS)
      subject = assertion.at_xpath("saml:Subject", NS)
      conditions = assertion.at_xpath("saml:Conditions", NS)
      conditions.add_next_sibling(subject.unlink)

      refute_empty @schema.validate(doc)
    end

    private

    def parse(response)
      Nokogiri::XML(response.mimic.unpack1("m0"))
    end

    def assert_valid(response)
      errors = @schema.validate(parse(response))
      assert_empty errors, errors.map(&:message).join("\n")
    end
  end
end
