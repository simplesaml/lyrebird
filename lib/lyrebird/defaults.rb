# frozen_string_literal: true

module Lyrebird
  NAMEID_EMAIL = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
  NAMEID_PERSISTENT = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
  NAMEID_TRANSIENT = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
  NAMEID_UNSPECIFIED = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"

  class Defaults
    attr_accessor :issuer
    attr_accessor :name_id
    attr_accessor :name_id_format
    attr_accessor :recipient
    attr_accessor :in_response_to
    attr_accessor :valid_for

    def initialize
      @issuer = "https://idp.example.com"
      @name_id = "user@example.com"
      @name_id_format = NAMEID_EMAIL
      @recipient = "https://sp.example.com/acs"
      @in_response_to = "_request_id"
      @valid_for = 300 # 5 minutes
    end
  end

  DEFAULTS = Defaults.new
end
