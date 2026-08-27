# frozen_string_literal: true

require "test_helper"

module Lyrebird
  class OptionsTest < Minitest::Test
    def setup
      @options = Options.new(issuer: "https://idp.test")
    end

    def test_to_h_returns_initial_values
      assert_equal({ issuer: "https://idp.test" }, @options.to_h)
    end

    def test_to_h_is_empty_without_values
      assert_empty Options.new.to_h
    end

    def test_string_keys_are_symbolized
      options = Options.new({ "issuer" => "https://idp.test" })
      assert_equal({ issuer: "https://idp.test" }, options.to_h)
    end

    def test_setter_stores_value
      @options.audience = "https://sp.test"
      assert_equal "https://sp.test", @options.to_h[:audience]
    end

    def test_setter_overwrites_initial_value
      @options.issuer = "https://other.test"
      assert_equal "https://other.test", @options.to_h[:issuer]
    end

    def test_getter_returns_initial_value
      assert_equal "https://idp.test", @options.issuer
    end

    def test_getter_returns_assigned_value
      @options.audience = "https://sp.test"
      assert_equal "https://sp.test", @options.audience
    end

    def test_getter_raises_for_unset_key
      assert_raises(NoMethodError) { @options.audience }
    end

    def test_getter_with_block_raises_for_unset_key
      ran = false
      assert_raises(NoMethodError) { @options.audience { ran = true } }
      refute ran
    end

    def test_responds_to_any_setter
      assert_respond_to @options, :audience=
    end

    def test_responds_to_set_key
      assert_respond_to @options, :issuer
    end

    def test_does_not_respond_to_unset_key
      refute_respond_to @options, :audience
    end

    def test_does_not_respond_to_implicit_conversions
      refute_respond_to @options, :to_ary
      refute_respond_to @options, :to_str
    end

    def test_reader_index
      assert_equal "https://idp.test", @options[:issuer]
    end

    def test_reader_index_accepts_string_key
      assert_equal "https://idp.test", @options["issuer"]
    end

    def test_reader_index_returns_nil_for_unset_key
      assert_nil @options[:audience]
    end

    def test_writer_index
      @options[:audience] = "https://sp.test"
      assert_equal "https://sp.test", @options.audience
    end

    def test_writer_index_accepts_string_key
      @options["audience"] = "https://sp.test"
      assert_equal "https://sp.test", @options.to_h[:audience]
    end

    def test_does_not_mutate_the_hash_it_was_given
      values = { issuer: "https://idp.test" }
      options = Options.new(values)
      options.audience = "https://sp.test"

      assert_equal({ issuer: "https://idp.test" }, values)
    end

    def test_defines_no_singleton_methods
      @options.audience = "https://sp.test"
      assert_empty @options.singleton_class.instance_methods(false)
    end
  end
end
