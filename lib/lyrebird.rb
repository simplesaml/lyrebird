# frozen_string_literal: true

require "base64"
require "openssl"
require "rexml"

require_relative "lyrebird/certificate"
require_relative "lyrebird/namespaces"
require_relative "lyrebird/version"

module Lyrebird
  class Error < StandardError; end
end
