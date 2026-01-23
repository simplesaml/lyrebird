# frozen_string_literal: true

module Lyrebird
  class Certificate
    attr_reader :private_key

    def self.generate
      new(OpenSSL::PKey::RSA.new(2048))
    end

    def initialize(private_key)
      @private_key = private_key
    end
  end
end
