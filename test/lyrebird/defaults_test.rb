# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class DefaultsTest < Minitest::Test
    def test_issuer
      assert_equal "https://idp.example.com", DEFAULTS.issuer
    end

    def test_name_id
      assert_equal "user@example.com", DEFAULTS.name_id
    end

    def test_name_id_format
      assert_equal NAMEID_EMAIL, DEFAULTS.name_id_format
    end

    def test_recipient
      assert_equal "https://sp.example.com/acs", DEFAULTS.recipient
    end

    def test_in_response_to
      assert_equal "_request_id", DEFAULTS.in_response_to
    end

    def test_valid_for
      assert_equal 300, DEFAULTS.valid_for
    end

    def test_audience
      assert_equal "https://sp.example.com", DEFAULTS.audience
    end

    def test_authn_context
      expected = AUTHN_PASSWORD_PROTECTED_TRANSPORT
      assert_equal expected, DEFAULTS.authn_context
    end

    def test_attributes
      expected = { first_name: "Test", last_name: "User" }
      assert_equal expected, DEFAULTS.attributes
    end
  end

  class ConfigureTest < Minitest::Test
    NAMESPACES = { "saml" => SAML_ASSERTION_NS }.freeze

    def setup
      @original = DEFAULTS
      Lyrebird.send(:remove_const, :DEFAULTS)
      Lyrebird.const_set(:DEFAULTS, Defaults.new)
    end

    def teardown
      Lyrebird.send(:remove_const, :DEFAULTS)
      Lyrebird.const_set(:DEFAULTS, @original)
    end

    def test_configure_yields_defaults
      yielded = nil
      Lyrebird.configure { |d| yielded = d }
      assert_same DEFAULTS, yielded
    end

    def test_configure_freezes_defaults
      Lyrebird.configure { |d| }
      assert DEFAULTS.frozen?
    end

    def test_configured_issuer_reaches_generated_xml
      issuer = "https://configured.example.com"
      refute_equal issuer, DEFAULTS.issuer
      Lyrebird.configure { |d| d.issuer = issuer }
      root = Response.build.document.root
      assert_equal issuer, root.at_xpath("saml:Issuer", NAMESPACES).text
    end

    def test_configured_name_id_reaches_generated_xml
      name_id = "configured@example.com"
      refute_equal name_id, DEFAULTS.name_id
      Lyrebird.configure { |d| d.name_id = name_id }
      root = Response.build.document.root
      xpath = "saml:Assertion/saml:Subject/saml:NameID"
      assert_equal name_id, root.at_xpath(xpath, NAMESPACES).text
    end
  end
end
