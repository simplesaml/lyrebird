# frozen_string_literal: true

module Lyrebird
  SAML_ASSERTION_NS = "urn:oasis:names:tc:SAML:2.0:assertion"
  SAML_PROTOCOL_NS = "urn:oasis:names:tc:SAML:2.0:protocol"
  XMLDSIG_NS = "http://www.w3.org/2000/09/xmldsig#"
  ENVELOPED_SIG = "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
  EXC_C14N = "http://www.w3.org/2001/10/xml-exc-c14n#"
  SHA256_DIGEST = "http://www.w3.org/2001/04/xmlenc#sha256"
  RSA_SHA256 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  CM_BEARER = "urn:oasis:names:tc:SAML:2.0:cm:bearer"
  ATTR_NAME_FORMAT = "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"
  STATUS_SUCCESS = "urn:oasis:names:tc:SAML:2.0:status:Success"
  XMLENC_NS = "http://www.w3.org/2001/04/xmlenc#"
  AES256_CBC = "http://www.w3.org/2001/04/xmlenc#aes256-cbc"
end
