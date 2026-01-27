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
```ruby
# With defaults
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
  r.valid_for = 300 # seconds
  r.idp_certificate = idp_cert
  r.sp_certificate = sp_cert
  r.sign_assertion = true
  r.sign_response = true
  r.encrypt_assertion = true

  r.attributes do |a|
    a.email = "user@example.com"
    a.groups = ["admin", "users"]
  end
end
```

### Getting the encoded response
```ruby
response.mimic    # Base64-encoded SAML response (for POST binding)
response.document # REXML::Document for inspection
```

### Signing
```ruby
idp_cert = Lyrebird::Certificate.generate

response = Lyrebird::Response.build do |r|
  r.idp_certificate = idp_cert
  r.sign_assertion = true # Sign the assertion (default: false)
  r.sign_response = true  # Sign the response (default: false)
end
```

### Encryption
Encrypt assertions using the SP's certificate so only the SP can decrypt them:
```ruby
idp_cert = Lyrebird::Certificate.generate
sp_cert = Lyrebird::Certificate.generate  # In practice, provided by the SP

response = Lyrebird::Response.build do |r|
  r.idp_certificate = idp_cert
  r.sp_certificate = sp_cert
  r.encrypt_assertion = true # Encrypt the assertion (default: false)
end
```

Signing and encryption can be combined. When both are enabled, the assertion is
signed first, then encrypted (sign-then-encrypt):
```ruby
response = Lyrebird::Response.build do |r|
  r.idp_certificate = idp_cert
  r.sp_certificate = sp_cert
  r.sign_assertion = true
  r.encrypt_assertion = true
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

### Generating a new certificate
```ruby
# With defaults
cert = Lyrebird::Certificate.generate

# With options
cert = Lyrebird::Certificate.generate(
  bits: 4096,                         # RSA key size (default: 2048)
  cn: "example.com",                  # Common Name
  o: "Acme",                          # Organization
  valid_for: 30,                      # Validity in days (default: 365)
  valid_until: Time.new(2999, 12, 31) # Specific expiration (overrides valid_for)
)
```

### Loading an existing certificate
```ruby
cert = Lyrebird::Certificate.load(
  private_key_pem: File.read("private_key.pem"),
  certificate_pem: File.read("certificate.pem")
)
```

### Exporting
```ruby
cert.private_key     # OpenSSL::PKey::RSA object
cert.certificate     # OpenSSL::X509::Certificate object
cert.private_key_pem # PEM-encoded private key
cert.certificate_pem # PEM-encoded certificate
cert.base64          # Base64-encoded certificate (for SAML metadata)
cert.fingerprint     # SHA256 fingerprint
```
