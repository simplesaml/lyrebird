# Lyrebird
A Ruby gem for mocking SAML Identity Provider (IdP) responses in test
environments.

## Installation
```ruby
gem "lyrebird", group: :test
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
