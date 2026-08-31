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
end
