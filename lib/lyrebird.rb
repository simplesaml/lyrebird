# frozen_string_literal: true

require "base64"
require "openssl"
require "rexml"
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
  class Error < StandardError; end
end
