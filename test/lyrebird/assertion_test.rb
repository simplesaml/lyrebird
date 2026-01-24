# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class AssertionTest < Minitest::Test
    def setup
      @assertion = Assertion.new.mimic
      @root = @assertion.root
    end

    def test_root_name
      assert_equal "Assertion", @root.name
      assert_equal "saml", @root.prefix
    end

    def test_root_namespace
      assert_equal SAML_ASSERTION_NS, @root.namespace
    end

    def test_root_id
      assert @root.attributes["ID"].start_with?("_")
    end

    def test_root_version
      assert_equal "2.0", @root.attributes["Version"]
    end

    def test_root_issue_instant
      instant = Time.iso8601(@root.attributes["IssueInstant"])
      assert_in_delta Time.now.to_i, instant.to_i, 1
    end
  end
end
