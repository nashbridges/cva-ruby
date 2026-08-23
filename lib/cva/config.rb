# frozen_string_literal: true

require_relative "merger"
require_relative "cache"

module Cva
  # Allows to define {Component#initialize} dependencies in a global way.
  module Config
    class << self
      # instance of this class will be injected as `:merger`. Defaults to {Merger}.
      attr_accessor :merger_class

      # instance of this class will be injected as `:cache`. Defaults to {Cache}.
      attr_accessor :cache_class
    end

    self.merger_class = Merger
    self.cache_class = Cache
  end
end
