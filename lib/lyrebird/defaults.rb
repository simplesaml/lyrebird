# frozen_string_literal: true

module Lyrebird
  class Defaults
    attr_accessor :issuer
    attr_accessor :name_id
    attr_accessor :name_id_format
    attr_accessor :recipient
    attr_accessor :in_response_to
    attr_accessor :valid_for
    attr_accessor :audience
    attr_accessor :authn_context
    attr_accessor :attributes

    def initialize
      @issuer = "https://idp.example.com"
      @name_id = "user@example.com"
      @name_id_format = NAMEID_EMAIL
      @recipient = "https://sp.example.com/acs"
      @in_response_to = "_request_id"
      @valid_for = 300 # 5 minutes
      @audience = "https://sp.example.com"

      @authn_context = AUTHN_PASSWORD_PROTECTED_TRANSPORT

      @attributes = {
        first_name: "Test",
        last_name: "User"
      }.freeze
    end
  end

  DEFAULTS = Defaults.new
end
