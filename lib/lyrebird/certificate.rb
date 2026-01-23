# frozen_string_literal: true

module Lyrebird
  class Certificate
    attr_reader :private_key, :certificate

    def self.generate(
      bits: 2048,
      cn: nil,
      o: nil,
      valid_for: 365,
      valid_until: nil
    )
      not_after = valid_until || Time.now + (valid_for * 24 * 60 * 60)
      new(OpenSSL::PKey::RSA.new(bits), cn, o, not_after)
    end

    def initialize(private_key, common_name, organization, not_after)
      @private_key = private_key
      @common_name = common_name
      @organization = organization
      @not_after = not_after
      @certificate = build_certificate
    end

    def private_key_pem
      @private_key.to_pem
    end

    private

    def build_certificate
      OpenSSL::X509::Certificate.new.tap do |c|
        c.public_key = @private_key.public_key
        c.subject = build_subject
        c.issuer = c.subject
        c.not_before = Time.now
        c.not_after = @not_after
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
