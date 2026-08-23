# frozen_string_literal: true

require "test_helper"

module Cva
  class ModelHelper
    class IntegrationTest < Minitest::Test
      def test_render
        a_class = Class.new
        a_class.class_eval do
          include ModelHelper.new(
            variants: {
              intent: {
                primary: "button-primary"
              },
              size: {
                small: "button-small"
              }
            }
          )
        end
        instance = a_class.new
        assert_equal "button-primary button-small", instance.cva_class_name(intent: :primary, size: :small)
      end

      def test_raises_error_during_definition
        a_class = Class.new
        assert_raises ArgumentError do
          a_class.class_eval do
            include ModelHelper.new(
              variants: :invalid
            )
          end
        end
      end

      def test_raises_error_during_render
        a_class = Class.new
        a_class.class_eval do
          include ModelHelper.new(
            variants: {
              intent: {
                primary: "button-primary"
              }
            }
          )
        end
        instance = a_class.new
        assert_raises ArgumentError do
          instance.cva_class_name(intent: :invalid)
        end
      end

      def test_method_name
        a_class = Class.new
        a_class.class_eval do
          include ModelHelper.new(
            method_name: "button",
            variants: {
              intent: {
                primary: "button-primary"
              }
            }
          )
        end
        instance = a_class.new
        assert_equal "button-primary", instance.button(intent: :primary)
      end

      def test_render_with_base
        a_class = Class.new
        a_class.class_eval do
          include ModelHelper.new(
            variants: {
              intent: {
                primary: "button-primary"
              }
            }
          )
        end
        instance = a_class.new
        assert_equal "button button-primary", instance.cva_class_name("button", intent: :primary)
      end
    end
  end
end
