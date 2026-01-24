# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class DefaultsTest < Minitest::Test
    def test_issuer
      assert_equal "https://idp.example.com", DEFAULTS.issuer
    end
  end
end
