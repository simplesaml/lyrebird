# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class IDTest < Minitest::Test
    def test_generate_starts_with_underscore
      assert ID.generate.start_with?("_")
    end
  end
end
