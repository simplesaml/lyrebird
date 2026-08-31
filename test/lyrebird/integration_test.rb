# frozen_string_literal: true

require "test_helper"
require "onelogin/ruby-saml"

module Lyrebird
  class IntegrationTest < Minitest::Test
    def setup
      @idp_cert = Certificate.default
    end

    def test_ruby_saml_parses_signed_response
      name_id = "user@example.com"

      response = Response.build(sign_with: @idp_cert) do |r|
        r.name_id = name_id
      end

      saml_response = consume(response.mimic)

      assert saml_response.is_valid?, saml_response.errors
      assert_equal name_id, saml_response.nameid
    end

    def test_ruby_saml_decrypts_signed_and_encrypted_response
      name_id = "user@example.com"
      email = "test@example.com"
      role = "admin"
      sp = Certificate.build

      response = Response.build(
        sign_with: @idp_cert,
        encrypt_with: sp
      ) do |r|
        r.name_id = name_id

        r.attributes do |a|
          a.email = email
          a.role = role
        end
      end

      saml_response = consume(response.mimic, sp: sp)

      assert saml_response.is_valid?, saml_response.errors
      assert_equal name_id, saml_response.nameid
      assert_equal email, saml_response.attributes["email"]
      assert_equal role, saml_response.attributes["role"]
    end

    def test_ruby_saml_parses_idp_initiated_response
      name_id = "user@example.com"
      email = "test@example.com"

      response = Response.build(sign_with: @idp_cert) do |r|
        r.in_response_to = nil
        r.destination = nil
        r.name_id = name_id

        r.attributes do |a|
          a.email = email
        end
      end

      saml_response = consume(response.mimic)

      assert saml_response.is_valid?, saml_response.errors
      assert_equal name_id, saml_response.nameid
      assert_equal email, saml_response.attributes["email"]
    end

    def test_ruby_saml_parses_multi_value_attributes
      name_id = "user@example.com"
      groups = ["admin", "users", "developers"]
      roles = ["editor", "viewer"]

      response = Response.build(sign_with: @idp_cert) do |r|
        r.name_id = name_id

        r.attributes do |a|
          a.groups = groups
          a.roles = roles
        end
      end

      saml_response = consume(response.mimic)

      assert saml_response.is_valid?, saml_response.errors
      assert_equal name_id, saml_response.nameid
      assert_equal groups, saml_response.attributes.multi("groups")
      assert_equal roles, saml_response.attributes.multi("roles")
    end

    def test_ruby_saml_validates_custom_validity_period
      name_id = "user@example.com"

      response = Response.build(sign_with: @idp_cert) do |r|
        r.name_id = name_id
        r.not_before = Time.now.utc - 60
        r.valid_for = 600
      end

      saml_response = consume(response.mimic)

      assert saml_response.is_valid?, saml_response.errors
      assert_equal name_id, saml_response.nameid
    end

    def test_ruby_saml_rejects_expired_assertion
      response = Response.build(sign_with: @idp_cert) do |r|
        r.valid_for = -10
      end

      saml_response = consume(response.mimic)

      assert_operator Time.now.utc, :>=, saml_response.not_on_or_after
      refute saml_response.is_valid?
    end

    def test_ruby_saml_rejects_not_yet_valid_assertion
      response = Response.build(sign_with: @idp_cert) do |r|
        r.not_before = Time.now.utc + 600
      end

      saml_response = consume(response.mimic)

      assert_operator Time.now.utc, :<, saml_response.not_before
      refute saml_response.is_valid?
    end

    def test_ruby_saml_rejects_tampered_signed_response
      response = Response.build(sign_with: @idp_cert) do |r|
        r.name_id = "user@example.com"

        r.attributes do |a|
          a.email = "user@example.com"
          a.role = "user"
        end
      end

      doc = Nokogiri::XML(response.mimic.unpack1("m0"))
      xpath = "//saml:Attribute[@Name='email']/saml:AttributeValue"
      email_attr = doc.at_xpath(xpath, { "saml" => SAML_ASSERTION_NS })
      email_attr.content = "attacker@evil.com"
      tampered = [doc.to_xml(save_with: 0)].pack("m0")

      saml_response = consume(tampered)

      refute saml_response.is_valid?
      assert_includes saml_response.errors.join(" "), "Signature"
    end

    private

    def consume(encoded, sp: nil)
      OneLogin::RubySaml::Response.new(encoded, settings: settings(sp: sp))
    end

    def settings(sp: nil)
      OneLogin::RubySaml::Settings.new.tap do |s|
        s.idp_cert = @idp_cert.x509_pem
        s.private_key = sp.key_pem if sp
        s.sp_entity_id = DEFAULTS.audience
        s.assertion_consumer_service_url = DEFAULTS.recipient
      end
    end
  end
end
