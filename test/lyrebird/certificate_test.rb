# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class CertificateTest < Minitest::Test
    def setup
      @certificate = Certificate.generate
    end

    def test_private_key_is_rsa
      assert_instance_of OpenSSL::PKey::RSA, @certificate.private_key
    end

    def test_private_key_defaults_to_2048_bits
      assert_equal 2048, @certificate.private_key.n.num_bits
    end

    def test_private_key_with_custom_bits
      certificate = Certificate.generate(bits: 4096)
      assert_equal 4096, certificate.private_key.n.num_bits
    end

    def test_certificate_is_x509
      assert_instance_of OpenSSL::X509::Certificate, @certificate.certificate
    end

    def test_certificate_not_before_is_now
      assert_in_delta Time.now, @certificate.certificate.not_before, 1
    end

    def test_certificate_not_after_is_one_year_from_now
      one_year = 365 * 24 * 60 * 60
      assert_in_delta Time.now + one_year, @certificate.certificate.not_after, 1
    end

    def test_certificate_is_signed
      assert @certificate.certificate.verify(@certificate.private_key)
    end

    def test_certificate_with_custom_subject
      certificate = Certificate.generate(cn: "Test", o: "Acme")
      assert_equal "/CN=Test/O=Acme", certificate.certificate.subject.to_s
    end

    def test_certificate_with_custom_valid_for
      certificate = Certificate.generate(valid_for: 30).certificate
      thirty_days = 30 * 24 * 60 * 60
      assert_in_delta Time.now + thirty_days, certificate.not_after, 1
    end

    def test_certificate_with_valid_until
      valid_until = Time.new(2030, 1, 1)
      certificate = Certificate.generate(valid_until: valid_until)
      assert_equal valid_until, certificate.certificate.not_after
    end
  end
end
