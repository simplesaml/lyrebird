# frozen_string_literal: true

module Lyrebird
  class Certificate
    LOCK = Mutex.new

    EXTENSIONS = {
      "basicConstraints" => "CA:FALSE",
      "keyUsage" => "digitalSignature,keyEncipherment"
    }.freeze

    attr_reader :key, :x509

    def self.default
      LOCK.synchronize { @default ||= build }
    end

    def self.build(**kwargs)
      config = OpenStruct.new(kwargs)
      yield config if block_given?
      new(**config.to_h)
    end

    def self.load(key_pem:, x509_pem:)
      key = OpenSSL::PKey::RSA.new(key_pem)
      x509 = OpenSSL::X509::Certificate.new(x509_pem)
      new(key: key, x509: x509)
    end

    def initialize(
      bits: 2048,
      cn: "lyrebird",
      o: nil,
      valid_for: 365,
      valid_until: nil,
      key: nil,
      x509: nil
    )
      @common_name = cn
      @organization = o
      @valid_for = valid_for
      @valid_until = valid_until
      @key = key || OpenSSL::PKey::RSA.new(bits)
      @x509 = x509 || build_x509
    end

    def key_pem
      @key.to_pem
    end

    def x509_pem
      @x509.to_pem
    end

    def fingerprint(algorithm = :sha256)
      digest = OpenSSL::Digest.new(algorithm.to_s)
      digest.hexdigest(@x509.to_der).upcase.scan(/../).join(":")
    end

    def base64
      [@x509.to_der].pack("m0")
    end

    private

    def build_x509
      now = Time.now.utc

      OpenSSL::X509::Certificate.new.tap do |c|
        c.version = 2
        c.serial = OpenSSL::BN.rand(64)
        c.public_key = @key.public_key
        c.subject = build_subject
        c.issuer = c.subject
        c.not_before = now
        c.not_after = @valid_until || now + (@valid_for * 86_400)

        EXTENSIONS.each do |oid, value|
          c.add_extension(OpenSSL::X509::Extension.new(oid, value, true))
        end

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
