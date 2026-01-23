# frozen_string_literal: true

module Lyrebird
  class Certificate
    attr_reader :private_key, :certificate

    def self.generate(bits: 2048, cn: nil, o: nil)
      new(OpenSSL::PKey::RSA.new(bits), cn, o)
    end

    def initialize(private_key, common_name, organization)
      @private_key = private_key
      @common_name = common_name
      @organization = organization
      @certificate = build_certificate
    end

    private

    def build_certificate
      OpenSSL::X509::Certificate.new.tap do |c|
        c.public_key = @private_key.public_key
        c.subject = build_subject
        c.issuer = c.subject
        c.not_before = Time.now
        c.not_after = Time.now + (365 * 24 * 60 * 60)
        c.sign(@private_key, OpenSSL::Digest::SHA256.new)
      end
    end

    def build_subject
      OpenSSL::X509::Name.new.tap do |name|
        name.add_entry("CN", @common_name) if @common_name
        name.add_entry("O", @organization) if @organization
      end
    end
  end
end
