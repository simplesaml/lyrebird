# frozen_string_literal: true

require "test_helper"
require "logger"
require "onelogin/ruby-saml"

module Lyrebird
  class IntegrationTest < Minitest::Test
    def test_ruby_saml_parses_signed_response
      idp_cert = Certificate.build
      issuer = "https://idp.example.com"
      name_id = "user@example.com"
      sp_entity_id = "https://sp.example.com"
      acs_url = "https://sp.example.com/acs"

      response = Response.build(sign_with: idp_cert) do |r|
        r.issuer = issuer
        r.name_id = name_id
      end

      settings = OneLogin::RubySaml::Settings.new
      settings.idp_cert = idp_cert.x509_pem
      settings.sp_entity_id = sp_entity_id
      settings.assertion_consumer_service_url = acs_url

      saml_response = OneLogin::RubySaml::Response.new(
        response.mimic,
        settings: settings
      )

      assert saml_response.is_valid?, saml_response.errors
      assert_equal name_id, saml_response.nameid
    end
  end
end
