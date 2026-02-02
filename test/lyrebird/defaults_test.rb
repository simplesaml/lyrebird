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
      expected = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
      assert_equal expected, DEFAULTS.authn_context
    end

    def test_attributes
      expected = { first_name: "Test", last_name: "User" }
      assert_equal expected, DEFAULTS.attributes
    end
  end

  class ConfigureTest < Minitest::Test
    def test_configure_yields_defaults
      yielded = nil
      Lyrebird.configure { |d| yielded = d }
      assert_same DEFAULTS, yielded
    end

    def test_configure_freezes_defaults
      Lyrebird.configure { |d| }
      assert DEFAULTS.frozen?
    end
  end
end
