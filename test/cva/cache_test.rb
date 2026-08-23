# frozen_string_literal: true

require "test_helper"

module Cva
  class Cache
    class FetchTest < Minitest::Test
      def test_block_is_called_only_once
        cache = Cache.new
        assert_equal "expensive call result", cache.fetch("hello") { "expensive call result" }
        assert_equal "expensive call result", cache.fetch("hello")
      end

      def test_exception_is_raised_and_is_not_memoized
        cache = Cache.new
        assert_raises ArgumentError do
          cache.fetch("hello") { raise ArgumentError }
        end
        assert_equal "expensive call result", cache.fetch("hello") { "expensive call result" }
      end

      def test_different_keys
        cache = Cache.new
        assert_equal "one", cache.fetch(1) { "one" }
        assert_equal "two", cache.fetch(2) { "two" }
        assert_equal "two", cache.fetch(2)
        assert_equal "one", cache.fetch(1)
      end
    end
  end
end
