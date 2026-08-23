# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class CertificateTest < Minitest::Test
    def setup
      @certificate = Certificate.default
    end

    def test_default_is_memoized
      assert_same Certificate.default, Certificate.default
    end

    def test_default_is_signed_by_its_own_key
      certificate = Certificate.default
      assert_instance_of Certificate, certificate
      assert certificate.x509.verify(certificate.key)
    end

    def test_key_is_rsa
      assert_instance_of OpenSSL::PKey::RSA, @certificate.key
    end

    def test_key_defaults_to_2048_bits
      assert_equal 2048, @certificate.key.n.num_bits
    end

    def test_key_with_custom_bits
      certificate = Certificate.build(bits: 4096)
      assert_equal 4096, certificate.key.n.num_bits
    end

    def test_x509_is_x509
      assert_instance_of OpenSSL::X509::Certificate, @certificate.x509
    end

    def test_x509_version_is_v3
      assert_equal 2, @certificate.x509.version
    end

    def test_x509_has_serial_number
      refute_nil @certificate.x509.serial
      assert @certificate.x509.serial.to_i > 0
    end

    def test_x509_not_before_is_now
      now = Time.now.utc
      certificate = Certificate.build
      assert_in_delta now, certificate.x509.not_before, 1
    end

    def test_x509_not_after_is_one_year_from_now
      expected = Time.now.utc + (365 * 24 * 60 * 60)
      certificate = Certificate.build
      assert_in_delta expected, certificate.x509.not_after, 1
    end

    def test_x509_is_signed
      assert @certificate.x509.verify(@certificate.key)
    end

    def test_x509_with_custom_subject
      certificate = Certificate.build(cn: "Test", o: "Acme")
      subject = certificate.x509.subject.to_s
      assert_equal "/CN=Test/O=Acme", subject
    end

    def test_x509_with_custom_valid_for
      certificate = Certificate.build(valid_for: 30).x509
      expected = Time.now.utc + (30 * 24 * 60 * 60)
      assert_in_delta expected, certificate.not_after, 1
    end

    def test_x509_with_valid_until
      valid_until = Time.new(2030, 1, 1)
      certificate = Certificate.build(valid_until: valid_until)
      assert_equal valid_until, certificate.x509.not_after
    end

    def test_key_pem
      assert @certificate.key_pem.start_with?("-----BEGIN")
    end

    def test_x509_pem
      assert @certificate.x509_pem.start_with?("-----BEGIN")
    end

    def test_fingerprint
      der = @certificate.x509.to_der
      hex = OpenSSL::Digest::SHA256.hexdigest(der).upcase
      assert_equal hex.scan(/../).join(":"), @certificate.fingerprint
    end

    def test_fingerprint_with_sha1
      der = @certificate.x509.to_der
      hex = OpenSSL::Digest::SHA1.hexdigest(der).upcase
      assert_equal hex.scan(/../).join(":"), @certificate.fingerprint(:sha1)
    end

    def test_base64
      der = @certificate.x509.to_der
      expected = Base64.strict_encode64(der)
      assert_equal expected, @certificate.base64
    end

    def test_build_with_block
      certificate = Certificate.build do |c|
        c.cn = "Name"
        c.o = "Org"
      end

      subject = certificate.x509.subject.to_s
      assert_equal "/CN=Name/O=Org", subject
    end

    def test_load
      loaded = Certificate.load(
        key_pem: @certificate.key_pem,
        x509_pem: @certificate.x509_pem,
      )

      assert_equal @certificate.fingerprint, loaded.fingerprint
    end
  end
end
