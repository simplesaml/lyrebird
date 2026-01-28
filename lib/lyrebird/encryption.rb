# frozen_string_literal: true

module Lyrebird
  class Encryption
    def initialize(element, certificate)
      @element = element
      @certificate = certificate
      @doc = element.document
      @aes_key = SecureRandom.random_bytes(32)
    end

    def encrypt
      build_encrypted_assertion
    end

    private

    def build_encrypted_assertion
      @doc.create_element("EncryptedAssertion").tap do |ea|
        @saml = ea.add_namespace_definition("saml", SAML_ASSERTION_NS)
        ea.namespace = @saml
        ea.add_child(build_encrypted_data)
      end
    end

    def build_encrypted_data
      @doc.create_element("EncryptedData").tap do |ed|
        @xenc = ed.add_namespace_definition("xenc", XMLENC_NS)
        ed.namespace = @xenc
        ed["Type"] = "#{XMLENC_NS}Element"

        enc_method = @doc.create_element("EncryptionMethod").tap do |em|
          em.namespace = @xenc
          em["Algorithm"] = AES256_CBC
        end

        ed.add_child(enc_method)
        ed.add_child(build_key_info)
        ed.add_child(build_cipher_data)
      end
    end

    def build_key_info
      @doc.create_element("KeyInfo").tap do |ki|
        @ds = ki.add_namespace_definition("ds", XMLDSIG_NS)
        ki.namespace = @ds
        ki.add_child(build_encrypted_key)
      end
    end

    def build_encrypted_key
      @doc.create_element("EncryptedKey").tap do |ek|
        ek.add_namespace_definition("xenc", XMLENC_NS)
        ek.namespace = @xenc

        enc_method = @doc.create_element("EncryptionMethod").tap do |em|
          em.namespace = @xenc
          em["Algorithm"] = RSA_OAEP
        end

        ek.add_child(enc_method)
        ek.add_child(build_encrypted_key_cipher_data)
      end
    end

    def build_encrypted_key_cipher_data
      public_key = @certificate.x509.public_key
      padding = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      encrypted_aes_key = public_key.public_encrypt(@aes_key, padding)

      @doc.create_element("CipherData").tap do |cd|
        cd.namespace = @xenc

        cipher_value = @doc.create_element("CipherValue").tap do |cv|
          cv.namespace = @xenc
          cv.content = Base64.strict_encode64(encrypted_aes_key)
        end

        cd.add_child(cipher_value)
      end
    end

    def build_cipher_data
      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.encrypt
      cipher.key = @aes_key
      iv = cipher.random_iv
      ciphertext = cipher.update(@element.to_xml) + cipher.final

      @doc.create_element("CipherData").tap do |cd|
        cd.namespace = @xenc

        cipher_value = @doc.create_element("CipherValue").tap do |cv|
          cv.namespace = @xenc
          cv.content = Base64.strict_encode64(iv + ciphertext)
        end

        cd.add_child(cipher_value)
      end
    end
  end
end
