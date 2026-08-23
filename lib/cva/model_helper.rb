# frozen_string_literal: true

require_relative "component"

module Cva
  # A syntax-sugar module. Removes boilerplate of instantiating and rendering
  # the {Component} within a class, e.g. a ViewComponent.
  #
  # Instead of resorting to global variables (which is fine in case you are
  # careful with namespacing):
  #
  # ```
  # class ButtonComponent < ViewComponent::Base
  #   BUTTON = Cva::Component.new(
  #     base: "button",
  #     variants: {
  #       intent: {
  #         primary: "button--primary",
  #         secondary: "button--secondary"
  #       }
  #     }
  #   )
  #
  #   def initialize(title:, intent:)
  #     @title = title
  #     @class_name = BUTTON.render(intent:)
  #   end
  # end
  # ```
  #
  # the same can be written as:
  #
  # ```
  # class ButtonComponent < ViewComponent::Base
  #   # The helper generates `cva_class_name` method, which delegates to
  #   # Component#render under the hood
  #   include Cva::ModelHelper.new(
  #     base: "button",
  #     variants: {
  #       intent: {
  #         primary: "button--primary",
  #         secondary: "button--secondary"
  #       }
  #     }
  #   )
  #
  #   def initialize(title:, intent:)
  #     @title = title
  #     @class_name = cva_class_name(intent:)
  #   end
  # end
  # ```
  #
  # All the {ModelHelper#initialize} params are passed straight to {Component#initialize},
  # except for `method_name`, which allows to override the name of the generated method:
  #
  # ```
  # class ButtonComponent < ViewComponent::Base
  #   include Cva::ModelHelper.new(
  #     method_name: "button_class",
  #     base: "button",
  #     variants: {
  #       intent: {
  #         primary: "button--primary",
  #         secondary: "button--secondary"
  #       }
  #     }
  #   )
  #
  #   def initialize(title:, intent:)
  #     @title = title
  #     @class_name = button_class(intent:)
  #   end
  # end
  # ```
  class ModelHelper < Module
    def initialize(method_name: "cva_class_name", **component_options)
      # Prepare a closure.
      # This `component` instance is shared by every class instance that includes
      # this module. It is exactly what we want in regards to performance:
      # calls to `render` are typical regardless of a particular instance,
      # so component's cache will be used in 99% cases.
      component = Component.new(**component_options)

      define_method(method_name) do |*args, **kwargs|
        component.render(*args, **kwargs)
      end
    end
  end
end
