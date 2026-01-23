# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class CertificateTest < Minitest::Test
    def test_private_key_is_rsa
      certificate = Certificate.generate
      assert_instance_of OpenSSL::PKey::RSA, certificate.private_key
    end

    def test_private_key_defaults_to_2048_bits
      certificate = Certificate.generate
      assert_equal 2048, certificate.private_key.n.num_bits
    end

    def test_private_key_with_custom_bits
      certificate = Certificate.generate(bits: 4096)
      assert_equal 4096, certificate.private_key.n.num_bits
    end

    def test_certificate_is_x509
      certificate = Certificate.generate
      assert_instance_of OpenSSL::X509::Certificate, certificate.certificate
    end

    def test_certificate_not_before_is_now
      certificate = Certificate.generate
      assert_in_delta Time.now, certificate.certificate.not_before, 1
    end

    def test_certificate_not_after_is_one_year_from_now
      certificate = Certificate.generate
      one_year = 365 * 24 * 60 * 60
      assert_in_delta Time.now + one_year, certificate.certificate.not_after, 1
    end

    def test_certificate_is_signed
      certificate = Certificate.generate
      assert certificate.certificate.verify(certificate.private_key)
    end
  end
end
