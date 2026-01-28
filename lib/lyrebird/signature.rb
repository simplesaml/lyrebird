# frozen_string_literal: true

module Lyrebird
  class Signature
    C14N_EXCLUSIVE = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0

    def initialize(element, certificate)
      @element = element
      @certificate = certificate
      @doc = element.document
    end

    def sign!
      issuer = @element.at_xpath("saml:Issuer", "saml" => SAML_ASSERTION_NS)
      issuer.add_next_sibling(build_signature)
      self
    end

    private

    def build_signature
      @doc.create_element("Signature").tap do |sig|
        @ds = sig.add_namespace_definition("ds", XMLDSIG_NS)
        sig.namespace = @ds

        sig.add_child(build_signed_info)
        sig.add_child(build_signature_value)
        sig.add_child(build_key_info)
      end
    end

    def build_signed_info
      @doc.create_element("SignedInfo").tap do |si|
        @signed_info = si
        si.add_namespace_definition("ds", XMLDSIG_NS)
        si.namespace = @ds

        c14n_method = @doc.create_element("CanonicalizationMethod").tap do |cm|
          cm.namespace = @ds
          cm["Algorithm"] = EXC_C14N
        end

        sig_method = @doc.create_element("SignatureMethod").tap do |sm|
          sm.namespace = @ds
          sm["Algorithm"] = RSA_SHA256
        end

        si.add_child(c14n_method)
        si.add_child(sig_method)
        si.add_child(build_reference)
      end
    end

    def build_signature_value
      @doc.create_element("SignatureValue").tap do |sv|
        sv.namespace = @ds
        canonical = canonicalize_signed_info
        sig = @certificate.sign(canonical)
        sv.content = Base64.strict_encode64(sig)
      end
    end

    def canonicalize_signed_info
      save_opts = Nokogiri::XML::Node::SaveOptions::AS_XML
      xml = @signed_info.to_xml(save_with: save_opts)
      pattern = "<ds:SignedInfo>"
      replacement = "<ds:SignedInfo xmlns:ds=\"#{XMLDSIG_NS}\">"
      xml = xml.sub(pattern, replacement)
      Nokogiri::XML(xml).root.canonicalize(C14N_EXCLUSIVE)
    end

    def build_key_info
      @doc.create_element("KeyInfo").tap do |ki|
        ki.namespace = @ds

        x509_data = @doc.create_element("X509Data").tap do |xd|
          xd.namespace = @ds

          x509_cert = @doc.create_element("X509Certificate").tap do |xc|
            xc.namespace = @ds
            xc.content = @certificate.base64
          end

          xd.add_child(x509_cert)
        end

        ki.add_child(x509_data)
      end
    end

    def build_reference
      @doc.create_element("Reference").tap do |ref|
        ref.namespace = @ds
        ref["URI"] = "##{@element["ID"]}"

        ref.add_child(build_transforms)

        digest_method = @doc.create_element("DigestMethod").tap do |dm|
          dm.namespace = @ds
          dm["Algorithm"] = SHA256_DIGEST
        end

        digest_value = @doc.create_element("DigestValue").tap do |dv|
          dv.namespace = @ds
          dv.content = compute_digest
        end

        ref.add_child(digest_method)
        ref.add_child(digest_value)
      end
    end

    def build_transforms
      @doc.create_element("Transforms").tap do |t|
        t.namespace = @ds

        enveloped = @doc.create_element("Transform").tap do |tr|
          tr.namespace = @ds
          tr["Algorithm"] = ENVELOPED_SIG
        end

        c14n = @doc.create_element("Transform").tap do |tr|
          tr.namespace = @ds
          tr["Algorithm"] = EXC_C14N
        end

        t.add_child(enveloped)
        t.add_child(c14n)
      end
    end

    def compute_digest
      canonical = @element.canonicalize(C14N_EXCLUSIVE)
      digest = OpenSSL::Digest::SHA256.digest(canonical)
      Base64.strict_encode64(digest)
    end
  end
end
