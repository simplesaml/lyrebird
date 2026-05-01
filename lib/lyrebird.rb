# frozen_string_literal: true

require "base64"
require "nokogiri"
require "openssl"
require "ostruct"
require "securerandom"
require "time"

require_relative "lyrebird/assertion"
require_relative "lyrebird/certificate"
require_relative "lyrebird/defaults"
require_relative "lyrebird/encryption"
require_relative "lyrebird/id"
require_relative "lyrebird/namespaces"
require_relative "lyrebird/response"
require_relative "lyrebird/signature"
require_relative "lyrebird/version"

module Lyrebird
  rails_env = ENV["RAILS_ENV"]&.downcase
  rack_env = ENV["RACK_ENV"]&.downcase

  if rails_env == "production" || rack_env == "production"
    warn <<~MESSAGE.strip
      [Lyrebird] WARNING: Loaded in production environment. \
      This library is for testing only.
    MESSAGE
  end

  def self.configure
    yield DEFAULTS
    DEFAULTS.freeze
  end
end
