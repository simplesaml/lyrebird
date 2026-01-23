# frozen_string_literal: true

module Lyrebird
  class Certificate
    attr_reader :private_key, :certificate

    def self.generate(bits: 2048)
      new(OpenSSL::PKey::RSA.new(bits))
    end

    def initialize(private_key)
      @private_key = private_key
      @certificate = build_certificate
    end

    private

    def build_certificate
      OpenSSL::X509::Certificate.new.tap do |c|
        c.public_key = @private_key.public_key
        c.not_before = Time.now
        c.not_after = Time.now + (365 * 24 * 60 * 60)
        c.sign(@private_key, OpenSSL::Digest::SHA256.new)
      end
    end
  end
end
