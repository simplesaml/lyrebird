# frozen_string_literal: true

module Lyrebird
  class Defaults
    attr_accessor :issuer

    def initialize
      @issuer = "https://idp.example.com"
    end
  end

  DEFAULTS = Defaults.new
end
