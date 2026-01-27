# frozen_string_literal: true

module Lyrebird
  class Certificate
    attr_reader :key, :x509

    def self.generate(bits: 2048, **options)
      new(OpenSSL::PKey::RSA.new(bits), **options)
    end

    def self.load(key_pem:, x509_pem:)
      key = OpenSSL::PKey::RSA.new(key_pem)
      x509 = OpenSSL::X509::Certificate.new(x509_pem)
      new(key, x509: x509)
    end

    def initialize(
      key,
      cn: nil,
      o: nil,
      valid_for: 365,
      valid_until: nil,
      x509: nil
    )
      @key = key
      @common_name = cn
      @organization = o
      @valid_for = valid_for
      @valid_until = valid_until
      @x509 = x509 || build_x509
    end

    def key_pem
      @key.to_pem
    end

    def x509_pem
      @x509.to_pem
    end

    def fingerprint
      OpenSSL::Digest::SHA256.hexdigest(@x509.to_der)
    end

    def base64
      Base64.strict_encode64(@x509.to_der)
    end

    private

    def build_x509
      now = Time.now

      OpenSSL::X509::Certificate.new.tap do |c|
        c.public_key = @key.public_key
        c.subject = build_subject
        c.issuer = c.subject
        c.not_before = now
        c.not_after = @valid_until || now + (@valid_for * 86_400)
        c.sign(@key, OpenSSL::Digest::SHA256.new)
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
