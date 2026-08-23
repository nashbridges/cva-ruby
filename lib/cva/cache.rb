module Cva
  # A default implementation of cache for {Component#render}. Based on Hash.
  #
  # @note Each {Component} instance gets its own {Cache} instance, i.e. the
  #   cache is not shared.
  #
  # Component#render is quite fast. The caching is performed only to avoid
  # useless work: {Component}'s state is immutable, and there's not many
  # permutations you can get from it.
  #
  # When the default implementation is used (which is in-memory one), make sure
  # a {Component} instance is long-lived, so that it can benefit from caching.
  # With {ModelHelper} this is true by default, no extra action is needed.
  #
  # In case you might want to override caching, e.g. to skip it during testing,
  # the best way to do it is via global config:
  #
  #  ```
  #  # config/initializers/cva.rb
  #
  #  class CvaNoCache
  #    def fetch(value)
  #      value
  #    end
  #  end
  #
  #  Cva::Config.cache_class = CvaNoCache
  #  ```
  class Cache
    def initialize
      @storage = {}
    end

    # @yield executes the block when cache is missed
    # @yieldreturn value that should be cached
    def fetch(value)
      @storage.fetch(value) do
        result = yield
        @storage[value] = result
        result
      end
    end
  end
end
