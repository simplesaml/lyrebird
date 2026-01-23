# frozen_string_literal: true

module Lyrebird
  class Certificate
    attr_reader :private_key

    def self.generate(bits: 2048)
      new(OpenSSL::PKey::RSA.new(bits))
    end

    def initialize(private_key)
      @private_key = private_key
    end
  end
end
