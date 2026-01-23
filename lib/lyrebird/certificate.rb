# frozen_string_literal: true

module Lyrebird
  class Certificate
    attr_reader :private_key, :certificate

    def self.generate(bits: 2048, **options)
      new(OpenSSL::PKey::RSA.new(bits), **options)
    end

    def self.load(private_key_pem:, certificate_pem:)
      private_key = OpenSSL::PKey::RSA.new(private_key_pem)
      certificate = OpenSSL::X509::Certificate.new(certificate_pem)
      new(private_key, certificate: certificate)
    end

    def initialize(
      private_key,
      cn: nil,
      o: nil,
      valid_for: 365,
      valid_until: nil,
      certificate: nil
    )
      @private_key = private_key
      @common_name = cn
      @organization = o
      @not_after = valid_until || Time.now + (valid_for * 24 * 60 * 60)
      @certificate = certificate || build_certificate
    end

    def private_key_pem
      @private_key.to_pem
    end

    def certificate_pem
      @certificate.to_pem
    end

    def fingerprint
      OpenSSL::Digest::SHA256.hexdigest(@certificate.to_der)
    end

    def base64
      Base64.strict_encode64(@certificate.to_der)
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
