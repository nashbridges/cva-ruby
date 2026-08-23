# frozen_string_literal: true

require_relative "config"

module Cva
  # The class builds a string list of CSS classes for a CSS component. First,
  # you initialize the instance with all the states (aka variants) that the
  # component can be in, along with the corresponding classes. Then you pass
  # exact variants into {#render}, which gets you back a string of concatenated
  # classes matching the state.
  #
  # The class is not responsible for rendering component's markup. You handle
  # the latter in a template and/or view component.
  #
  # The class is immutable. {#render} does not perform side effects, except
  # for looking into cache (see {Cache}).
  #
  # @example
  #   button = Cva::Component.new(
  #     base: "button",
  #     variants: {
  #       size: {
  #         small: "button--small",
  #         medium: "button--medium",
  #         large: "button--large",
  #       }
  #     }
  #   )
  #
  #   button.render(size: :large) # => "button button--large"
  #
  class Component
    # @!visibility private
    VARIANTS_VALIDATION_MESSAGE = <<~'EOF'
      :variants should be a Hash in a form of
      {
        variant1: {
          condition1: 'condition-1-class',                    # a string
          condition2: ['condition-2-class', 'another-class'], # an array of strings is also fine
          condition3: ->(base) { "#{base}_class" }            # or a proc-like object accepting base class and returning a string or an array of strings
          condition4: nil,                                    # `nil` means a no-op condition
        },
        variant2: {...},
      }
    EOF

    # @!visibility private
    BASE_VALIDATION_MESSAGE = <<~EOF
      base should be a string, or an array of strings, or nil
    EOF

    # @!visibility private
    BASE_IS_REQUIRED_FOR_PROC_VALIDATION_MESSAGE = <<~EOF
      base is required when condition is proc-like, either explicitly, or implicitly
      (via defaults in :base config)
    EOF

    # @!visibility private
    SINGLE_ARGUMENT_PROC_VALIDATION_MESSAGE = <<~EOF
      if condition is proc-like, it has to accept a single string argument (the base class will be passed during evaluation)
    EOF

    # @!visibility private
    DEFAULT_VARIANTS_VALIDATION_MESSAGE = <<~EOF
      :default_variants should be a Hash in a form of
      {
        variant1: :condition1_for_variant1,
        variant2: :condition3_for_variant2,
      }
      where both variants and their conditions should be already known (defined by you
      in :variants config)
    EOF

    # @!visibility private
    COMPOUND_VARIANTS_VALIDATION_MESSAGE = <<~EOF
      :compound_variants should be an array where each element is a Hash in form of
      {
        variant1: :condition1_for_variant1,                             # AND condition1
        variant2: [:condition2_for_variant2, :condition3_for_variant2], # AND (condition2 OR condition3)
        class: 'compound-variant-class' # can also be an array of strings, or proc returning string or array of strings
      }
      where both variants and their conditions should be already known (defined by you
      in :variants config).
    EOF

    # @!visibility private
    RENDER_VARIANTS_VALIDATION_MESSAGE = <<~EOF
      keyword arguments should be in a form of
        variant1: :condition1_for_variant1,
        variant2: :condition3_for_variant2,
      where both variants and their conditions should be already known (defined by you
      in :variants config).
      Input should provide all the variants, either explicitly, or implicitly (via defaults
      in :default_variants config).
    EOF

    # A map of variants, default_variants, compound_variants and base
    attr_reader :config

    # A cache instance to hold results of {#render} invocation. See {Cache}
    # @return [#fetch]
    attr_reader :cache

    # A CSS class merger instance. See {Merger}
    # @return [#call]
    attr_reader :merger

    # @param variants [{VariantKey => {OptionKey => String, Array<String>,
    #   #call, nil}}] a map of variants and their options to CSS classes. \
    #   A variant combines a group of options, so the map is nested. Think of
    #   a variant as a dimension of states in the CSS component. For a button
    #   component it can be "size" (small, medium, large) or "visual"
    #   (outlined, solid). Variant and option keys can be anything, but usually
    #   symbols are used.
    #   ```
    #     {
    #       visual: {
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       }
    #     }
    #   ```
    #   When a variant option resolves to multiple classes, you can specify
    #   them as an array of strings. It has the same effect as you would pass
    #   the classes as a long string list, but allows for a nice formatting:
    #   ```
    #     {
    #       visual: {
    #         outlined: [
    #           "border-1",
    #           "border-color-blue",
    #           "border-radius-2",
    #         ]
    #       }
    #     }
    #   ```
    #   or even nicer:
    #   ```
    #     {
    #       visual: {
    #         outlined: %w[
    #           border-1
    #           border-color-blue
    #           border-radius-2
    #         ]
    #       }
    #     }
    #   ```
    #   Passing `nil` as a class value means this variant option is an empty
    #   one. This is commonly used with boolean options when only `true`
    #   corresponds to something meaningful (notice the usage of `=>`, so that
    #   the keys are booleans, and not symbols):
    #   ```
    #     {
    #       badge: {
    #         true => "button--badge",
    #         false => nil, # no class is added to the output for this option
    #       }
    #     }
    #   ```
    #   If you have more than 2 options with one being empty, a common approach
    #   is to name it as "unset":
    #   ```
    #     {
    #       visual: {
    #         unset: nil,
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       }
    #     }
    #   ```
    #   You can pass lambda (or generally any object that responds to #call) as
    #   a class name. When resolved, the lambda receives base class as an input
    #   and should return a class or an array of classes. This is only useful in
    #   cases when you override base class in #render.
    #   ```
    #     {
    #       visual: {
    #         outlined: ->(base) { "#{base}--outlined" },
    #         solid: ->(base) { "#{base}--solid" },
    #       }
    #     }
    #   ```
    #
    # @param base [String, Array<String>] a CSS class, or an array of classes
    #   that should be included into every output. You can override it in #render.
    #
    # @param default_variants [{VariantKey => OptionKey}] a map of variants and
    #   their options that should be used by default in every output. You can
    #   override it in #render.
    #   ```
    #     {
    #       visual: :solid,
    #       size: :medium,
    #       badge: false,
    #     }
    #   ```
    #
    # @param compound_variants [Array<{VariantKey, :class => OptionKey,
    #   Array<OptionKey>, String, Array<String>, #call}>] a list of CSS classes
    #   that should be applied only for a specific combination of variants.\
    #   The class is passed under the `:class` key, and it allows the same format as
    #   in `:variants` (a string, an array of string, or an object that responds
    #   to #call). \
    #   Here the class is added to the output when both `:size` is `:large` and
    #   `:badge` is `true`:
    #   ```
    #   [{
    #     size: :large, # if size is `:small` or `:medium`, this compound variant is not applied
    #     badge: true,  # or if badge is `false`, this compound variant is off too
    #     class: "button--large-with-badge",
    #   }]
    #   ```
    #   You can pass an array of option keys, that means any of the options is fine:
    #   ```
    #   [{
    #     size: [:small, :medium],
    #     visual: :solid,
    #     class: "button--small-solid-or-medium-solid",
    #   }]
    #   ```
    #
    # @param cache [#fetch] (see {#cache})
    #
    # @param merger [#call] (see {#merger})
    #
    # @raise [ArgumentError] if input does not match the schema
    def initialize(
      variants:,
      base: nil,
      default_variants: nil,
      compound_variants: nil,
      cache: Config.cache_class.new,
      merger: Config.merger_class.new
    )
      @config = {}
      config[:variants] = validate_and_coerce_config_variants!(variants)
      config[:base] = validate_and_coerce_config_base!(base)
      config[:default_variants] = validate_and_coerce_config_default_variants!(default_variants)
      config[:compound_variants] = validate_and_coerce_config_compound_variants!(compound_variants)
      @cache = cache
      @merger = merger
    end

    # @param base [String, Array<String>] overrides (or sets) base CSS class or classes
    #
    # @param variants [{VariantKey => OptionKey}] currently chosen variants. Overrides
    #   `:default_variants` if those were set in {#initialize}
    #
    # @return [String] space-delimitered list of CSS classes.
    #
    # @raise [ArgumentError] if base and/or variants do not match the schema, or some
    #   variant keys are missing
    #
    # @example Simple variants
    #   button = Cva::Component.new(
    #     variants: {
    #       size: {
    #         small: "button--small",
    #         medium: "button--medium",
    #         large: "button--large",
    #       },
    #       visual: {
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       }
    #     }
    #   )
    #
    #   button.render(size: :small, visual: :solid) # => "button--small button--solid"
    #   button.render(visual: :solid, size: :small) # => "button--small button--solid" <-- order is preserved
    #   button.render(size: :medium) # => ERROR! `:visual` variant is missing
    #   button.render(size: :medium, visual: :text) # => ERROR! `:visual` variant option was not declared in config
    #
    # @example Base
    #   button = Cva::Component.new(
    #     base: "button",
    #     variants: {
    #       visual: {
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       }
    #     }
    #   )
    #
    #   button.render(visual: :outlined) # => "button button--outlined"
    #   button.render(visual: :solid) # => "button button--solid"
    #
    # @example Array of CSS classes
    #   button = Cva::Component.new(
    #     variants: {
    #       visual: {
    #         outlined: [
    #           "border-1",
    #           "border-color-blue",
    #           "border-radius-2",
    #         ]
    #       }
    #     }
    #   )
    #
    #   button.render(visual: :outlined) # => "border-1 border-color-blue border-radius-2"
    #
    # @example `nil` as CSS class
    #   button = Cva::Component.new(
    #     variants: {
    #       visual: {
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       },
    #       badge: {
    #         true => "button--badge",
    #         false => nil,
    #       }
    #     }
    #   )
    #
    #   button.render(visual: outlined, badge: true) # => "button--outlined button--badge"
    #   button.render(visual: outlined, badge: false) # => "button--outlined"
    #
    # @example Default variants
    #   button = Cva::Component.new(
    #     variants: {
    #       size: {
    #         small: "button--small",
    #         medium: "button--medium",
    #         large: "button--large",
    #       },
    #       visual: {
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       }
    #     },
    #     default_variants: {
    #       size: :medium,
    #       visual: :solid,
    #     }
    #   )
    #
    #   button.render # => "button--medium button--solid"
    #   button.render(size: :large) # => "button--large button--solid"
    #   button.render(size: :small, visual: :outlined) # => "button--small button--outlined"
    #
    # @example Skip variant with the "unset" pattern
    #   button = Cva::Component.new(
    #     variants: {
    #       size: {
    #         small: "button--small",
    #         medium: "button--medium",
    #         large: "button--large",
    #       },
    #       visual: {
    #         unset: nil,
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       }
    #     },
    #     default_variants: {
    #       size: :medium,
    #       visual: :solid,
    #     }
    #   )
    #
    #   button.render # => "button--medium button--solid"
    #   button.render(visual: :unset) # => "button--medium"
    #
    # @example Compound variants
    #   button = Cva::Component.new(
    #     variants: {
    #       size: {
    #         small: "button--small",
    #         medium: "button--medium",
    #         large: "button--large",
    #       },
    #       visual: {
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       }
    #     },
    #     compound_variants: [{
    #       size: :small,
    #       visual: :solid,
    #       class: "button--small-and-solid",
    #     }]
    #   )
    #
    #   button.render(size: :small, visual: :solid) # => "button--small button--solid button--small-and-solid"
    #   button.render(size: :medium, visual: :solid) # => "button--medium button--solid"
    #   button.render(size: :small, visual: :outlined) # => "button--small button--outlined"
    #
    # @example Compound variants with variant options array
    #   button = Cva::Component.new(
    #     variants: {
    #       size: {
    #         small: "button--small",
    #         medium: "button--medium",
    #         large: "button--large",
    #       },
    #       visual: {
    #         outlined: "button--outlined",
    #         solid: "button--solid",
    #       }
    #     },
    #     compound_variants: [{
    #       size: [:small, :medium],
    #       visual: :solid,
    #       class: "button--small-or-medium-size-and-solid",
    #     }]
    #   )
    #
    #   button.render(size: :small, visual: :solid) # => "button--small button--solid button--small-or-medium-size-and-solid"
    #   button.render(size: :medium, visual: :solid) # => "button--medium button--solid button--small-or-medium-size-and-solid"
    #   button.render(size: :small, visual: :outlined) # => "button--small button--outlined"
    #
    # @example lamdba as CSS class + base override
    #   button = Cva::Component.new(
    #     base: "button",
    #     variants: {
    #       visual: {
    #         outlined: ->(base) { "#{base}--outlined" },
    #         solid: ->(base) { "#{base}--solid" },
    #       }
    #     }
    #   )
    #
    #   button.render(visual: outlined) # => "button button--outlined"
    #   button.render("superbutton", visual: outlined) # => "superbutton superbutton--outlined"
    def render(base = nil, **variants)
      cache.fetch([base, variants]) do
        final_base = validate_and_coerce_render_base!(base)
        input_variants = validate_and_coerce_render_variants!(variants)

        class_names = [
          final_base
        ]

        config[:variants].each_pair do |config_variant, config_conditions|
          condition = input_variants.fetch(config_variant)
          class_name = config_conditions.fetch(condition)
          class_names << resolve_potentially_callable_class_name!(class_name, base: final_base)
        end

        config[:compound_variants].each do |compound_variant|
          compound_variant => {class: class_name, **variant_conditions}
          if variant_conditions.all? { |variant, conditions| conditions.include?(input_variants.fetch(variant)) }
            class_names << resolve_potentially_callable_class_name!(class_name, base: final_base)
          end
        end

        merger.call(class_names.flatten)
      end
    end

    private def validate_non_empty_hash!(hash)
      case hash
      in {**rest} if rest.size > 0
        hash
      end
    end

    private def validate_and_coerce_class_name!(a_class, allow_empty: true)
      case a_class
      in String
        Array(a_class)
      in [*strings] if strings.all?(String) && (allow_empty || strings.size > 0)
        a_class
      end
    end

    private def validate_and_coerce_potentially_callable_class_name!(a_class, allow_empty: true)
      if a_class.respond_to?(:call)
        begin
          result = a_class.call("TEST PROBE")
        rescue ArgumentError
          raise ArgumentError, SINGLE_ARGUMENT_PROC_VALIDATION_MESSAGE
        end

        validate_and_coerce_class_name!(result, allow_empty:)
        a_class
      else
        validate_and_coerce_class_name!(a_class, allow_empty:)
      end
    end

    private def validate_variants_conditions!(variants_conditions)
      if !variants_conditions.each_pair.all? { |variant, condition| config[:variants].dig(variant, condition) }
        raise NoMatchingPatternError
      end
    end

    private def validate_and_coerce_config_variants!(input)
      validate_non_empty_hash!(input)

      input.transform_values do |conditions|
        validate_non_empty_hash!(conditions)

        conditions.transform_values do |value|
          if value.nil?
            []
          else
            validate_and_coerce_potentially_callable_class_name!(value)
          end
        end
      end
    rescue NoMatchingPatternError
      raise ArgumentError, VARIANTS_VALIDATION_MESSAGE
    end

    private def validate_and_coerce_config_base!(input)
      if input.nil?
        return []
      end

      validate_and_coerce_class_name!(input)
    rescue NoMatchingPatternError
      raise ArgumentError, BASE_VALIDATION_MESSAGE
    end

    private def validate_and_coerce_config_default_variants!(input)
      if input.nil?
        return {}
      end

      input => Hash
      validate_variants_conditions!(input)

      input
    rescue NoMatchingPatternError
      raise ArgumentError, DEFAULT_VARIANTS_VALIDATION_MESSAGE
    end

    private def validate_and_coerce_config_variants_conditions!(variants_conditions)
      if variants_conditions.size == 0
        raise NoMatchingPatternError
      end

      coerced_variant_condition_pairs = variants_conditions.map do |variant, condition|
        coerced_condition = Array(condition)

        if coerced_condition.size == 0
          raise NoMatchingPatternError
        end

        if !coerced_condition.all? { |condition| config[:variants].dig(variant, condition) }
          raise NoMatchingPatternError
        end

        [variant, coerced_condition]
      end

      coerced_variant_condition_pairs.flatten(0).to_h
    end

    private def validate_and_coerce_config_compound_variants!(input)
      if input.nil?
        return []
      end

      input => Array
      input.map do |compound_variant|
        compound_variant => {class: class_name, **variant_conditions}

        final_variants_conditions = validate_and_coerce_config_variants_conditions!(variant_conditions)
        final_class = validate_and_coerce_potentially_callable_class_name!(class_name, allow_empty: false)

        {class: final_class, **final_variants_conditions}
      end
    rescue NoMatchingPatternError
      raise ArgumentError, COMPOUND_VARIANTS_VALIDATION_MESSAGE
    end

    private def validate_and_coerce_render_base!(base)
      if base.nil?
        return config[:base]
      end

      validate_and_coerce_class_name!(base)
    rescue NoMatchingPatternError
      raise ArgumentError, BASE_VALIDATION_MESSAGE
    end

    private def validate_and_coerce_render_variants!(input)
      validate_variants_conditions!(input)

      full_variants_conditions = {
        **config[:default_variants],
        **input
      }

      if full_variants_conditions.keys.sort != config[:variants].keys.sort
        raise NoMatchingPatternError
      end

      full_variants_conditions
    rescue NoMatchingPatternError
      raise ArgumentError, RENDER_VARIANTS_VALIDATION_MESSAGE
    end

    private def resolve_potentially_callable_class_name!(class_name, base:)
      if class_name.respond_to?(:call)
        if base.size == 0
          raise ArgumentError, BASE_IS_REQUIRED_FOR_PROC_VALIDATION_MESSAGE
        end

        base.map do |each_base|
          resolved_class_name = class_name.call(each_base)
          resolved_class_name
        end
      else
        class_name
      end
    end
  end
end
