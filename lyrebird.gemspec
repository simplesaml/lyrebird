# frozen_string_literal: true

require_relative "lib/lyrebird/version"

Gem::Specification.new do |spec|
  spec.name = "lyrebird"
  spec.version = Lyrebird::VERSION
  spec.authors = ["Josh"]

  spec.summary = "Mimics SAML Identity Provider (IdP) responses for testing"
  spec.homepage = "https://github.com/simplesaml/lyrebird"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = `git ls-files -z`.split("\x0")
  spec.files.delete("Gemfile")
  spec.files.delete(".gitignore")
  spec.files.reject! { |f| f.start_with?("bin/") }

  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
  spec.add_dependency "nokogiri"
  spec.add_dependency "ostruct"

  # ruby-saml's gemspec has a conditional dependency on logger for Ruby >= 3.4,
  # but it was evaluated at gem build time (on Ruby < 3.4), so the published gem
  # doesn't include it.
  spec.add_development_dependency "logger"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "ruby-saml"
end
