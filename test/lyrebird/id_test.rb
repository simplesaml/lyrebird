# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class IDTest < Minitest::Test
    def test_generate_starts_with_underscore
      assert ID.generate.start_with?("_")
    end

    def test_generate_contains_uuid
      id = ID.generate
      uuid = id[1..]
      uuid_pattern = /\A[0-9a-f-]{36}\z/
      assert_match uuid_pattern, uuid
    end
  end
end
