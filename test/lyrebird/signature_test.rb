# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class SignatureTest < Minitest::Test
    def setup
      @certificate = Certificate.generate
      @assertion = Assertion.new.document
      @element = @assertion.root
      @signature = Signature.new(@element, certificate: @certificate)
    end
  end
end
