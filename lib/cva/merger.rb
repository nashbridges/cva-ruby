# frozen_string_literal: true

module Cva
  # A default implementation of CSS classes merger for {Component#render}. The logic is simple:
  # input elements are joined with space as is.
  #
  # When using the library with Tailwind, you'll need a merger with deduplicating behavior.
  # You may want to wrap one of the existing libraries:
  #
  # - https://github.com/abuisman/tail_merge
  # - https://github.com/gjtorikian/tailwind_merge
  #
  # An example integration:
  #
  # ```
  # # config/initializers/cva.rb
  #
  # require "tail_merge"
  #
  # class CvaTailwindMerger
  #   def call(classes)
  #     TailMerge.merge(classes)
  #   end
  # end
  #
  # Cva::Config.merger_class = CvaTailwindMerger
  # ```
  class Merger
    # @param classes [Array<String>] a list of CSS classes resolved in {Component#render}
    # @return [String] final string of CSS classes
    def call(classes)
      classes.join(" ")
    end
  end
end
