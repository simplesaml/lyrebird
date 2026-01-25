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

    response = Lyrebird::Response.new(
      issuer: "https://idp.example.com",
      destination: saml_consume_url,
      recipient: saml_consume_url,
      audience: root_url,
      name_id: user.email,
      attributes: {
        "email" => user.email,
        "first_name" => user.first_name,
        "last_name" => user.last_name
      }
    )

    post saml_consume_path, params: { SAMLResponse: response.mimic }

    assert_redirected_to dashboard_path
    assert_equal user.id, session[:user_id]
  end
end
```

## Response
Creates complete SAML responses with embedded assertions.

### Creating a response
```ruby
# With defaults
response = Lyrebird::Response.new

# With options
response = Lyrebird::Response.new(
  issuer: "https://idp.example.com",
  destination: "https://sp.example.com/acs",
  in_response_to: "_request_id",
  name_id: "user@example.com",
  name_id_format: Lyrebird::NAMEID_EMAIL,
  recipient: "https://sp.example.com/acs",
  audience: "https://sp.example.com",
  valid_for: 300, # seconds
  attributes: {
    "email" => "user@example.com",
    "groups" => ["admin", "users"]
  }
)
```

### Getting the encoded response
```ruby
response.mimic    # Base64-encoded SAML response (for POST binding)
response.document # REXML::Document for inspection
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
Lyrebird::DEFAULTS.attributes = { "role" => "user" }
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
  valid_until: Time.new(2026, 12, 31) # Specific expiration (overrides valid_for)
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
