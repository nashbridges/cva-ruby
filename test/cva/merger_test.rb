# frozen_string_literal: true

require "test_helper"

module Cva
  class Merger
    class CallTest < Minitest::Test
      def test_joins_with_space
        merger = Merger.new
        assert_equal "one two", merger.call(["one", "two"])
      end
    end
  end
end
