# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class CertificateTest < Minitest::Test
    def test_private_key_is_rsa
      certificate = Certificate.generate
      assert_instance_of OpenSSL::PKey::RSA, certificate.private_key
    end

    def test_private_key_is_2048_bit
      certificate = Certificate.generate
      assert_equal 2048, certificate.private_key.n.num_bits
    end
  end
end
