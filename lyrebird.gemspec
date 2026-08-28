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

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/releases",
    "bug_tracker_uri" => "#{spec.homepage}/issues"
  }

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE.md"]

  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", ">= 1.14"

  # ruby-saml requires base64 and logger without declaring either, and neither
  # is a default gem as of Ruby 3.4.
  spec.add_development_dependency "base64"
  spec.add_development_dependency "logger"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "ruby-saml"
end
