# frozen_string_literal: true

require "test_helper"

module Cva
  class Component
    class InitializeVariantsTest < Minitest::Test
      def test_requires_variants
        error = assert_raises(ArgumentError) do
          Component.new
        end
        assert_equal error.message, "missing keyword: :variants"
      end

      def test_requires_variants_to_be_hash
        error = assert_raises(ArgumentError) do
          Component.new(variants: "hello")
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_variants_as_empty_hash
        error = assert_raises(ArgumentError) do
          Component.new(variants: {})
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_requires_conditions_to_be_hash
        error = assert_raises(ArgumentError) do
          Component.new(variants: {
            variant1: "hello"
          })
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_accepts_conditions_values_to_be_string
        component = Component.new(
          variants: {
            variant1: {
              condition1: "class-for-condition1"
            }
          }
        )
        assert_equal({
          variant1: {
            condition1: ["class-for-condition1"]
          }
        }, component.config[:variants])
      end

      def test_accepts_conditions_values_to_be_array_of_strings
        component = Component.new(
          variants: {
            variant1: {
              condition1: ["class-for-condition1", "another-class"]
            }
          }
        )
        assert_equal({
          variant1: {
            condition1: ["class-for-condition1", "another-class"]
          }
        }, component.config[:variants])
      end

      def test_accepts_conditions_values_to_be_nil
        component = Component.new(
          variants: {
            variant1: {
              condition1: nil
            }
          }
        )
        assert_equal({
          variant1: {
            condition1: []
          }
        }, component.config[:variants])
      end

      def test_accepts_conditions_values_to_be_empty_array
        component = Component.new(
          variants: {
            variant1: {
              condition1: []
            }
          }
        )
        assert_equal({
          variant1: {
            condition1: []
          }
        }, component.config[:variants])
      end

      def test_does_not_coerce_variants_and_conditions_keys
        component = Component.new(
          variants: {
            3 => {
              true => "true-class",
              "string" => "string-class"
            }
          }
        )
        assert_equal({
          3 => {
            true => ["true-class"],
            "string" => ["string-class"]
          }
        }, component.config[:variants])
      end

      def test_rejects_conditions_as_empty_hash
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: {
              variant1: {}
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_boolean
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: {
              variant1: {
                condition1: false
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_number
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: {
              variant1: {
                condition1: 546
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_hash
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: {
              variant1: {
                condition1: {key1: "hello"}
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_mixed_array
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: {
              variant1: {
                condition1: ["hello", 42]
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_accepts_conditions_values_to_be_proc_returning_a_string
        proc = ->(base) { "#{base}_class" }
        component = Component.new(
          variants: {
            variant1: {
              condition1: proc
            }
          }
        )
        assert_equal({
          variant1: {
            condition1: proc
          }
        }, component.config[:variants])
      end

      def test_accepts_conditions_values_to_be_proc_returning_an_array_of_strings
        proc = ->(base) { ["#{base}_class", "another-base"] }
        component = Component.new(
          variants: {
            variant1: {
              condition1: proc
            }
          }
        )
        assert_equal({
          variant1: {
            condition1: proc
          }
        }, component.config[:variants])
      end

      def test_rejects_conditions_values_to_be_proc_without_argument
        proc = -> { "a-class" }
        error = assert_raises ArgumentError do
          Component.new(
            variants: {
              variant1: {
                condition1: proc
              }
            }
          )
        end
        assert_equal SINGLE_ARGUMENT_PROC_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_proc_returning_nil
        proc = ->(base) {}
        error = assert_raises ArgumentError do
          Component.new(
            variants: {
              variant1: {
                condition1: proc
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_proc_returning_number
        proc = ->(base) { 42 }
        error = assert_raises ArgumentError do
          Component.new(
            variants: {
              variant1: {
                condition1: proc
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_proc_returning_boolean
        proc = ->(base) { false }
        error = assert_raises ArgumentError do
          Component.new(
            variants: {
              variant1: {
                condition1: proc
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_proc_returning_hash
        proc = ->(base) { {hello: "base-class"} }
        error = assert_raises ArgumentError do
          Component.new(
            variants: {
              variant1: {
                condition1: proc
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_proc_returning_mixed_array
        proc = ->(base) { ["#{base}_class", 42] }
        error = assert_raises ArgumentError do
          Component.new(
            variants: {
              variant1: {
                condition1: proc
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_conditions_values_to_be_proc_returning_proc
        proc = ->(base) { ->(base) { "base-class" } }
        error = assert_raises ArgumentError do
          Component.new(
            variants: {
              variant1: {
                condition1: proc
              }
            }
          )
        end
        assert_equal VARIANTS_VALIDATION_MESSAGE, error.message
      end
    end

    class InitializeBaseTest < Minitest::Test
      def valid_variants
        {variant1: {condition1: "class-for-condition1"}}
      end

      def test_base_is_optional
        component = Component.new(
          variants: valid_variants
        )
        assert_equal([], component.config[:base])
      end

      def test_accepts_to_be_string
        component = Component.new(
          variants: valid_variants,
          base: "base-class"
        )
        assert_equal(["base-class"], component.config[:base])
      end

      def test_accepts_to_be_array_of_strings
        component = Component.new(
          variants: valid_variants,
          base: ["base-class-1", "base-class-2"]
        )
        assert_equal(["base-class-1", "base-class-2"], component.config[:base])
      end

      def test_accepts_to_be_nil
        component = Component.new(
          variants: valid_variants,
          base: nil
        )
        assert_equal([], component.config[:base])
      end

      def test_accepts_to_be_empty_array
        component = Component.new(
          variants: valid_variants,
          base: []
        )
        assert_equal([], component.config[:base])
      end

      def test_rejects_to_be_number
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: valid_variants,
            base: 42
          )
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_to_be_hash
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: valid_variants,
            base: {condition1: "hello"}
          )
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_to_be_boolean
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: valid_variants,
            base: false
          )
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_to_be_mixed_array
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: valid_variants,
            base: ["class-1", 42]
          )
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_to_be_proc
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: valid_variants,
            base: ->(base) { "base-class" }
          )
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end
    end

    class InitializeDefaultVariantsTest < Minitest::Test
      def valid_variants
        {variant1: {condition1: "class-for-condition1"}}
      end

      def test_default_variants_is_optional
        component = Component.new(variants: valid_variants)
        assert_equal({}, component.config[:default_variants])
      end

      def test_accepts_to_be_nil
        component = Component.new(
          variants: valid_variants,
          default_variants: nil
        )
        assert_equal({}, component.config[:default_variants])
      end

      def test_accepts_to_be_empty_hash
        component = Component.new(
          variants: valid_variants,
          default_variants: {}
        )
        assert_equal({}, component.config[:default_variants])
      end

      def test_requires_to_be_hash
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: valid_variants,
            default_variants: 42
          )
        end
        assert_equal DEFAULT_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_accepts_valid_variant_and_condition
        variants = {
          intent: {
            primary: "primary-class"
          }
        }
        component = Component.new(
          variants:,
          default_variants: {intent: :primary}
        )
        assert_equal({intent: :primary}, component.config[:default_variants])
      end

      def test_does_not_require_all_variants_to_be_specified
        variants = {
          intent: {
            primary: "primary-class"
          },
          size: {
            small: "small-class"
          }
        }
        component = Component.new(
          variants:,
          default_variants: {size: :small}
        )
        assert_equal({size: :small}, component.config[:default_variants])
      end

      def test_rejects_invalid_variant
        variants = {
          intent: {
            primary: "primary-class"
          },
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            default_variants: {
              intent: :primary,
              invalid_variant: :small
            }
          )
        end
        assert_equal DEFAULT_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_invalid_condition
        variants = {
          intent: {
            primary: "primary-class"
          },
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            default_variants: {
              intent: :primary,
              size: :invalid_option
            }
          )
        end
        assert_equal DEFAULT_VARIANTS_VALIDATION_MESSAGE, error.message
      end
    end

    class InitializeCompoundVariantsTest < Minitest::Test
      def valid_variants
        {variant1: {condition1: "class-for-condition1"}}
      end

      def test_compound_variants_is_optional
        component = Component.new(variants: valid_variants)
        assert_equal([], component.config[:compound_variants])
      end

      def test_accepts_to_be_nil
        component = Component.new(
          variants: valid_variants,
          compound_variants: nil
        )
        assert_equal([], component.config[:compound_variants])
      end

      def test_accepts_to_be_empty_array
        component = Component.new(
          variants: valid_variants,
          compound_variants: []
        )
        assert_equal([], component.config[:compound_variants])
      end

      def test_requires_to_be_array
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: valid_variants,
            compound_variants: "hello"
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_requires_all_elements_to_be_hash
        error = assert_raises(ArgumentError) do
          Component.new(
            variants: valid_variants,
            compound_variants: ["hello", {hi: "world"}]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_accepts_valid_variant_and_condition
        variants = {
          intent: {
            primary: "primary-class"
          },
          size: {
            small: "small-class"
          }
        }
        component = Component.new(
          variants:,
          compound_variants: [{
            intent: :primary,
            size: :small,
            class: "compound-class"
          }]
        )
        assert_equal([{
          intent: [:primary],
          size: [:small],
          class: ["compound-class"]
        }], component.config[:compound_variants])
      end

      def test_does_not_require_all_variants_to_be_specified
        variants = {
          intent: {
            primary: "primary-class"
          },
          size: {
            small: "small-class"
          }
        }
        component = Component.new(
          variants:,
          compound_variants: [{
            size: :small,
            class: "compound-class"
          }]
        )
        assert_equal([{
          size: [:small],
          class: ["compound-class"]
        }], component.config[:compound_variants])
      end

      def test_requires_class
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_accepts_class_to_be_array_of_strings
        variants = {
          size: {
            small: "small-class"
          }
        }
        component = Component.new(
          variants:,
          compound_variants: [{
            size: :small,
            class: ["compound-class"]
          }]
        )
        assert_equal([{
          size: [:small],
          class: ["compound-class"]
        }], component.config[:compound_variants])
      end

      def test_accepts_array_of_conditions
        variants = {
          size: {
            small: "small-class",
            medium: "medium-class"
          }
        }
        component = Component.new(
          variants:,
          compound_variants: [{
            size: [:small, :medium],
            class: ["compound-class"]
          }]
        )
        assert_equal([{
          size: [:small, :medium],
          class: ["compound-class"]
        }], component.config[:compound_variants])
      end

      def test_rejects_array_of_conditions_with_invalid_condition
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: [:small, :invalid_condition],
              class: "compound-class"
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_empty_array
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: []
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_mixed_array
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: ["compound-class", 42]
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_nil
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: nil
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_number
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: 42
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_hash
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: {hello: "world"}
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_boolean
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: false
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_requires_at_least_one_variant
        variants = {
          intent: {
            primary: "primary-class"
          },
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              class: "compound-class"
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_invalid_variant
        variants = {
          intent: {
            primary: "primary-class"
          },
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              intent: :primary,
              invalid_variant: :small,
              class: "compound-class"
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_invalid_condition
        variants = {
          intent: {
            primary: "primary-class"
          },
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              intent: :primary,
              size: :invalid_condition,
              class: "compound-class"
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_empty_array_conditions
        variants = {
          intent: {
            primary: "primary-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              intent: [],
              class: "compound-class"
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_accepts_class_to_be_proc_returning_string
        proc = ->(base) { "#{base}-class" }
        variants = {
          size: {
            small: "small-class"
          }
        }
        component = Component.new(
          variants:,
          compound_variants: [{
            size: :small,
            class: proc
          }]
        )
        assert_equal([{
          size: [:small],
          class: proc
        }], component.config[:compound_variants])
      end

      def test_accepts_class_to_be_proc_returning_array_of_strings
        proc = ->(base) { ["#{base}-class", "another-class"] }
        variants = {
          size: {
            small: "small-class"
          }
        }
        component = Component.new(
          variants:,
          compound_variants: [{
            size: :small,
            class: proc
          }]
        )
        assert_equal([{
          size: [:small],
          class: proc
        }], component.config[:compound_variants])
      end

      def test_rejects_class_to_be_proc_without_argument
        proc = -> { "a-class" }
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: proc
            }]
          )
        end
        assert_equal SINGLE_ARGUMENT_PROC_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_proc_returning_number
        proc = ->(base) { 42 }
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: proc
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_proc_returning_mixed_array
        proc = ->(base) { ["a-class", 42] }
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: proc
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_proc_returning_hash
        proc = ->(base) { {hello: "world"} }
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: proc
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_proc_returning_empty_array
        proc = ->(base) { [] }
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: proc
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_proc_returning_nil
        proc = ->(base) {}
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: proc
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_proc_returning_boolean
        proc = ->(base) { false }
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: proc
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_class_to_be_proc_returning_proc
        proc = ->(base) { ->(base) { "base-class" } }
        variants = {
          size: {
            small: "small-class"
          }
        }
        error = assert_raises(ArgumentError) do
          Component.new(
            variants:,
            compound_variants: [{
              size: :small,
              class: proc
            }]
          )
        end
        assert_equal COMPOUND_VARIANTS_VALIDATION_MESSAGE, error.message
      end
    end

    class InitializeCacheTest < Minitest::Test
      def valid_variants
        {variant1: {condition1: "class-for-condition1"}}
      end

      def test_default_instance_comes_from_config
        cache_class = Class.new

        Config.stub :cache_class, cache_class do
          component = Component.new(
            variants: valid_variants
          )
          cache = component.cache
          assert cache.instance_of? cache_class
        end
      end

      def test_override_default_instance
        cache = Object.new
        component = Component.new(
          cache:,
          variants: valid_variants
        )
        assert_equal cache, component.cache
      end
    end

    class InitializeMergerTest < Minitest::Test
      def valid_variants
        {variant1: {condition1: "class-for-condition1"}}
      end

      def test_default_instance_comes_from_config
        merger_class = Class.new

        Config.stub :merger_class, merger_class do
          component = Component.new(
            variants: valid_variants
          )
          merger = component.merger
          assert merger.instance_of? merger_class
        end
      end

      def test_override_default_instance
        merger = Object.new
        component = Component.new(
          merger:,
          variants: valid_variants
        )
        assert_equal merger, component.merger
      end
    end

    class RenderTest < Minitest::Test
      def test_string_condition
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        assert_equal "button-primary", component.render(intent: :primary)
      end

      def test_array_of_strings_condition
        component = Component.new(
          variants: {
            intent: {
              primary: ["button", "button-primary"]
            }
          }
        )
        assert_equal "button button-primary", component.render(intent: :primary)
      end

      def test_multiple_variants
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            },
            size: {
              small: "button-small"
            }
          }
        )
        assert_equal "button-primary button-small", component.render(intent: :primary, size: :small)
      end

      def test_nil_condition
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            },
            size: {
              default: nil
            }
          }
        )
        assert_equal "button-primary", component.render(intent: :primary, size: :default)
      end

      def test_requires_condition
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        error = assert_raises(ArgumentError) do
          component.render
        end
        assert_equal RENDER_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_requires_all_conditions
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            },
            size: {
              small: "button-small"
            }
          }
        )
        error = assert_raises(ArgumentError) do
          component.render(size: :small)
        end
        assert_equal RENDER_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_invalid_variant
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        error = assert_raises(ArgumentError) do
          component.render(invalid_variant: :primary)
        end
        assert_equal RENDER_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_rejects_invalid_condition
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        error = assert_raises(ArgumentError) do
          component.render(primary: :whatever)
        end
        assert_equal RENDER_VARIANTS_VALIDATION_MESSAGE, error.message
      end

      def test_does_not_rely_on_the_order_of_input_keywords
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            },
            size: {
              small: "button-small"
            }
          }
        )
        assert_equal "button-secondary button-small", component.render(intent: :secondary, size: :small)
        assert_equal "button-secondary button-small", component.render(size: :small, intent: :secondary)
      end

      def test_proc_condition
        component = Component.new(
          base: "button",
          variants: {
            intent: {
              primary: ->(base) { "#{base}-primary" }
            }
          }
        )
        assert_equal "button button-primary", component.render(intent: :primary)
      end

      def test_proc_condition_with_array_of_strings_base
        component = Component.new(
          base: ["button", "extra-class"],
          variants: {
            intent: {
              primary: ->(base) { "#{base}-primary" }
            }
          }
        )
        assert_equal "button extra-class button-primary extra-class-primary", component.render(intent: :primary)
      end

      def test_proc_condition_base_override
        component = Component.new(
          base: "button",
          variants: {
            intent: {
              primary: ->(base) { "#{base}-primary" }
            }
          }
        )
        assert_equal "my-button my-button-primary", component.render("my-button", intent: :primary)
      end

      def test_proc_condition_requires_base
        component = Component.new(
          variants: {
            intent: {
              primary: ->(base) { "#{base}-primary" }
            }
          }
        )
        error = assert_raises ArgumentError do
          component.render(intent: :primary)
        end
        assert_equal BASE_IS_REQUIRED_FOR_PROC_VALIDATION_MESSAGE, error.message
      end

      def test_cache
        mock = Minitest::Mock.new
        mock.expect(:fetch, "cached-button-class", [[nil, {intent: :secondary, size: :small}]])
        component = Component.new(
          cache: mock,
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            },
            size: {
              small: "button-small"
            }
          }
        )
        assert_equal "cached-button-class", component.render(intent: :secondary, size: :small)
        mock.verify
      end

      def test_cache_with_base
        mock = Minitest::Mock.new
        mock.expect(:fetch, "cached-button-class", [["button", {size: :small}]])
        component = Component.new(
          cache: mock,
          variants: {
            size: {
              small: "button-small"
            }
          }
        )
        assert_equal "cached-button-class", component.render("button", size: :small)
        mock.verify
      end

      def test_merger
        mock = Minitest::Mock.new
        mock.expect(:call, "merged-class", [["button-secondary", "button-small"]])
        component = Component.new(
          merger: mock,
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            },
            size: {
              small: "button-small"
            }
          }
        )
        assert_equal "merged-class", component.render(intent: :secondary, size: :small)
        mock.verify
      end
    end

    class RenderBaseTest < Minitest::Test
      def test_string_config
        component = Component.new(
          base: "button",
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        assert_equal "button button-primary", component.render(intent: :primary)
      end

      def test_array_of_strings_config
        component = Component.new(
          base: ["button", "button-base"],
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        assert_equal "button button-base button-primary", component.render(intent: :primary)
      end

      def test_render_string_argument
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        assert_equal "button button-primary", component.render("button", intent: :primary)
      end

      def test_render_array_of_strings_argument
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        assert_equal "button button-base button-primary", component.render(["button", "button-base"], intent: :primary)
      end

      def test_render_argument_override_config
        component = Component.new(
          base: "button",
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        assert_equal "override-button button-primary", component.render("override-button", intent: :primary)
      end

      def test_render_argument_rejects_mixed_array
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        error = assert_raises ArgumentError do
          component.render(["button", 42], intent: :primary)
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end

      def test_render_argument_rejects_number
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        error = assert_raises ArgumentError do
          component.render(42, intent: :primary)
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end

      def test_render_argument_rejects_boolean
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        error = assert_raises ArgumentError do
          component.render(false, intent: :primary)
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end

      def test_render_argument_rejects_proc
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        error = assert_raises ArgumentError do
          component.render(->(base) { "button" }, intent: :primary)
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end

      def test_render_argument_rejects_hash
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          }
        )
        error = assert_raises ArgumentError do
          component.render({base: "button"}, intent: :primary)
        end
        assert_equal BASE_VALIDATION_MESSAGE, error.message
      end
    end

    class RenderDefaultVariantsTest < Minitest::Test
      def test_all_defaults
        component = Component.new(
          default_variants: {
            intent: :primary,
            size: :small
          },
          variants: {
            intent: {
              primary: "button-primary"
            },
            size: {
              small: "button-small"
            }
          }
        )
        assert_equal "button-primary button-small", component.render
      end

      def test_overrides_default
        component = Component.new(
          default_variants: {
            intent: :primary
          },
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            }
          }
        )
        assert_equal "button-secondary", component.render(intent: :secondary)
      end

      def test_requires_extra_non_default_variant
        component = Component.new(
          default_variants: {
            intent: :primary
          },
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            },
            size: {
              small: "button-small"
            }
          }
        )
        error = assert_raises(ArgumentError) do
          component.render(intent: :secondary)
        end
        assert_equal RENDER_VARIANTS_VALIDATION_MESSAGE, error.message
      end
    end

    class RenderCompoundVariantsTest < Minitest::Test
      def test_matches_one
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          },
          compound_variants: [
            {
              intent: :primary,
              class: "button-primary-compound"
            }
          ]
        )
        assert_equal "button-primary button-primary-compound", component.render(intent: :primary)
      end

      def test_matches_two
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            },
            size: {
              small: "button-small"
            }
          },
          compound_variants: [
            {
              intent: :primary,
              size: :small,
              class: "button-primary-and-small-compound"
            }
          ]
        )
        assert_equal "button-primary button-small button-primary-and-small-compound", component.render(
          intent: :primary,
          size: :small
        )
      end

      def test_does_not_match_if_partially
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            },
            size: {
              small: "button-small",
              medium: "button-medium"
            }
          },
          compound_variants: [
            {
              intent: :primary,
              size: :small,
              class: "button-primary-and-small-compound"
            }
          ]
        )

        assert_equal "button-secondary button-small", component.render(
          intent: :secondary,
          size: :small
        )
        assert_equal "button-primary button-medium", component.render(
          intent: :primary,
          size: :medium
        )
      end

      def test_matches_array_of_conditions
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            }
          },
          compound_variants: [
            {
              intent: [:primary, :secondary],
              class: "button-compound"
            }
          ]
        )
        assert_equal "button-primary button-compound", component.render(intent: :primary)
        assert_equal "button-secondary button-compound", component.render(intent: :secondary)
      end

      def test_matches_multiple_array_of_conditions
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            },
            size: {
              small: "button-small",
              medium: "button-medium"
            }
          },
          compound_variants: [
            {
              intent: [:primary, :secondary],
              size: [:small, :medium],
              class: "button-compound"
            }
          ]
        )
        assert_equal "button-primary button-small button-compound", component.render(intent: :primary, size: :small)
        assert_equal "button-primary button-medium button-compound", component.render(intent: :primary, size: :medium)
        assert_equal "button-secondary button-small button-compound", component.render(intent: :secondary, size: :small)
        assert_equal "button-secondary button-medium button-compound", component.render(intent: :secondary, size: :medium)
      end

      def test_does_not_match_array_of_conditions
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary",
              tertiary: "button-tertiary"
            }
          },
          compound_variants: [
            {
              intent: [:primary, :secondary],
              class: "button-compound"
            }
          ]
        )
        assert_equal "button-tertiary", component.render(intent: :tertiary)
      end

      def test_array_of_strings
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          },
          compound_variants: [
            {
              intent: :primary,
              class: ["button-primary-compound", "another-compound"]
            }
          ]
        )
        assert_equal "button-primary button-primary-compound another-compound", component.render(intent: :primary)
      end

      def test_matches_with_default_variants
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            },
            size: {
              small: "button-small"
            }
          },
          default_variants: {
            size: :small
          },
          compound_variants: [
            {
              intent: :primary,
              size: :small,
              class: "button-primary-and-small-compound"
            }
          ]
        )
        assert_equal "button-primary button-small button-primary-and-small-compound", component.render(intent: :primary)
      end

      def test_does_not_match_with_default_variants_when_overridden
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary",
              secondary: "button-secondary"
            },
            size: {
              small: "button-small"
            }
          },
          default_variants: {
            intent: :primary,
            size: :small
          },
          compound_variants: [
            {
              intent: :primary,
              size: :small,
              class: "button-primary-and-small-compound"
            }
          ]
        )
        assert_equal "button-secondary button-small", component.render(intent: :secondary)
      end

      def test_proc_returning_string
        component = Component.new(
          base: "button",
          variants: {
            intent: {
              primary: "button-primary"
            }
          },
          compound_variants: [
            {
              intent: :primary,
              class: ->(base) { "#{base}-compound" }
            }
          ]
        )
        assert_equal "button button-primary button-compound", component.render(intent: :primary)
      end

      def test_proc_returning_array_of_strings
        component = Component.new(
          base: "button",
          variants: {
            intent: {
              primary: "button-primary"
            }
          },
          compound_variants: [
            {
              intent: :primary,
              class: ->(base) { ["#{base}-compound", "another-class"] }
            }
          ]
        )
        assert_equal "button button-primary button-compound another-class", component.render(intent: :primary)
      end

      def test_proc_base_override
        component = Component.new(
          base: "button",
          variants: {
            intent: {
              primary: "button-primary"
            }
          },
          compound_variants: [
            {
              intent: :primary,
              class: ->(base) { "#{base}-compound" }
            }
          ]
        )
        assert_equal "my-button button-primary my-button-compound", component.render("my-button", intent: :primary)
      end

      def test_proc_requires_base
        component = Component.new(
          variants: {
            intent: {
              primary: "button-primary"
            }
          },
          compound_variants: [
            {
              intent: :primary,
              class: ->(base) { "#{base}-compound" }
            }
          ]
        )
        error = assert_raises ArgumentError do
          component.render(intent: :primary)
        end
        assert_equal BASE_IS_REQUIRED_FOR_PROC_VALIDATION_MESSAGE, error.message
      end
    end
  end
end
