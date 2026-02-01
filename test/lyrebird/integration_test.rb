# frozen_string_literal: true

require "test_helper"
require "onelogin/ruby-saml"

module Lyrebird
  class IntegrationTest < Minitest::Test
    def setup
      unless defined?(@@idp_cert)
        @@idp_cert = Certificate.build
        @@sp_cert = Certificate.build
      end

      @idp_cert = @@idp_cert
      @sp_cert = @@sp_cert
    end

    def test_ruby_saml_parses_signed_response
      name_id = "user@example.com"

      response = Response.build(sign_with: @idp_cert) do |r|
        r.name_id = name_id
      end

      settings = OneLogin::RubySaml::Settings.new.tap do |s|
        s.idp_cert = @idp_cert.x509_pem
        s.sp_entity_id = DEFAULTS.audience
        s.assertion_consumer_service_url = DEFAULTS.recipient
      end

      saml_response = OneLogin::RubySaml::Response.new(
        response.mimic,
        settings: settings
      )

      assert saml_response.is_valid?, saml_response.errors
      assert_equal name_id, saml_response.nameid
    end

    def test_ruby_saml_decrypts_signed_and_encrypted_response
      name_id = "user@example.com"
      email = "test@example.com"
      role = "admin"

      response = Response.build(
        sign_with: @idp_cert,
        encrypt_with: @sp_cert
      ) do |r|
        r.name_id = name_id

        r.attributes do |a|
          a.email = email
          a.role = role
        end
      end

      settings = OneLogin::RubySaml::Settings.new.tap do |s|
        s.idp_cert = @idp_cert.x509_pem
        s.private_key = @sp_cert.key_pem
        s.sp_entity_id = DEFAULTS.audience
        s.assertion_consumer_service_url = DEFAULTS.recipient
      end

      saml_response = OneLogin::RubySaml::Response.new(
        response.mimic,
        settings: settings
      )

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

      settings = OneLogin::RubySaml::Settings.new.tap do |s|
        s.idp_cert = @idp_cert.x509_pem
        s.sp_entity_id = DEFAULTS.audience
        s.assertion_consumer_service_url = DEFAULTS.recipient
      end

      saml_response = OneLogin::RubySaml::Response.new(
        response.mimic,
        settings: settings
      )

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

      settings = OneLogin::RubySaml::Settings.new.tap do |s|
        s.idp_cert = @idp_cert.x509_pem
        s.sp_entity_id = DEFAULTS.audience
        s.assertion_consumer_service_url = DEFAULTS.recipient
      end

      saml_response = OneLogin::RubySaml::Response.new(
        response.mimic,
        settings: settings
      )

      assert saml_response.is_valid?, saml_response.errors
      assert_equal name_id, saml_response.nameid
      assert_equal groups, saml_response.attributes.multi("groups")
      assert_equal roles, saml_response.attributes.multi("roles")
    end
  end
end
