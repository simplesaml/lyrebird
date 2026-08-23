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
      pattern = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
      assert_match pattern, uuid
    end
  end
end
