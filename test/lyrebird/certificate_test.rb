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
  end
end
