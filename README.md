# Lyrebird
A Ruby gem for mimicking SAML Identity Provider (IdP) responses in test
environments.

## Installation
```ruby
gem "lyrebird", group: :test
```

## Basic example
```ruby
# test/integration/saml_test.rb
class SAMLTest < ActionDispatch::IntegrationTest
  test "consume creates a session" do
    user = users(:alice)

    response = Lyrebird::Response.build do |r|
      r.issuer = "https://idp.example.com"
      r.destination = saml_consume_url
      r.recipient = saml_consume_url
      r.audience = root_url
      r.name_id = user.email

      r.attributes do |a|
        a.email = user.email
        a.first_name = user.first_name
        a.last_name = user.last_name
      end
    end

    post saml_consume_path, params: { SAMLResponse: response.mimic }

    assert_redirected_to dashboard_path
    assert_equal user.id, session[:user_id]
  end
end
```

## Response
Builds complete SAML responses with embedded assertions.

### Building a response
Defaults produce an SP-initiated response. See
[IdP-initiated SSO](#idp-initiated-sso) to omit `InResponseTo` and
`Destination`.
```ruby
# With defaults (SP-initiated)
response = Lyrebird::Response.build

# With options
response = Lyrebird::Response.build do |r|
  r.issuer = "https://idp.example.com"
  r.destination = "https://sp.example.com/acs"
  r.in_response_to = "_request_id"
  r.name_id = "user@example.com"
  r.name_id_format = Lyrebird::NAMEID_EMAIL
  r.recipient = "https://sp.example.com/acs"
  r.audience = "https://sp.example.com"
  r.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:Password"
  r.not_before = Time.now.utc
  r.valid_for = 300 # seconds
  r.sign_with = idp_cert
  r.encrypt_with = sp_cert

  r.attributes do |a|
    a.email = "user@example.com"
    a.groups = ["admin", "users"]
  end
end
```

### IdP-initiated SSO
For unsolicited (IdP-initiated) flows where there is no AuthnRequest,
set `in_response_to` and `destination` to `nil` to omit them from the
XML entirely:
```ruby
response = Lyrebird::Response.build do |r|
  r.in_response_to = nil
  r.destination = nil
  r.name_id = "user@example.com"
end
```

### Getting the encoded response
```ruby
response.mimic    # Base64-encoded SAML response (for POST binding)
response.document # REXML::Document for inspection
```

### Signing
Sign both the assertion and response with an IdP certificate:
```ruby
idp_cert = Lyrebird::Certificate.build
response = Lyrebird::Response.build(sign_with: idp_cert)
```

### Encryption
Encrypt assertions using the SP's certificate so only the SP can decrypt them:
```ruby
sp_cert = Lyrebird::Certificate.build
response = Lyrebird::Response.build(encrypt_with: sp_cert)
```

Signing and encryption can be combined:
```ruby
response = Lyrebird::Response.build do |r|
  r.sign_with = idp_cert
  r.encrypt_with = sp_cert
end
```

### NameID Formats
```ruby
Lyrebird::NAMEID_EMAIL       # emailAddress (default)
Lyrebird::NAMEID_PERSISTENT  # persistent
Lyrebird::NAMEID_TRANSIENT   # transient
Lyrebird::NAMEID_UNSPECIFIED # unspecified
```

## Configuring defaults
Override defaults globally for all responses/assertions:
```ruby
# test/test_helper.rb
Lyrebird::DEFAULTS.issuer = "https://custom.example.com"
Lyrebird::DEFAULTS.recipient = "https://custom.example.com/acs"
Lyrebird::DEFAULTS.audience = "https://custom.example.com"
Lyrebird::DEFAULTS.name_id = "default@example.com"
Lyrebird::DEFAULTS.valid_for = 600 # 10 minutes
Lyrebird::DEFAULTS.attributes = { role: "user" }
```

## Certificate
Generates and manages X.509 certificates for signing SAML responses.

### Building a certificate
```ruby
# With defaults
cert = Lyrebird::Certificate.build

# With options
cert = Lyrebird::Certificate.build do |c|
  c.bits = 4096                           # RSA key size (default: 2048)
  c.cn = "example.com"                    # Common Name
  c.o = "Acme"                            # Organization
  c.valid_for = 30                        # Days (default: 365)
  c.valid_until = Time.new(2999, 12, 31)  # Overrides valid_for
end
```

### Loading an existing certificate
```ruby
cert = Lyrebird::Certificate.load(
  key_pem: File.read("private_key.pem"),
  x509_pem: File.read("certificate.pem")
)
```

### Using a certificate
```ruby
cert.key          # OpenSSL::PKey::RSA private key
cert.x509         # OpenSSL::X509::Certificate object
cert.key_pem      # PEM-encoded private key
cert.x509_pem     # PEM-encoded certificate
cert.sign(data)   # Sign data with RSA-SHA256
cert.base64       # Base64-encoded certificate (for SAML metadata)
cert.fingerprint  # SHA256 fingerprint
```
