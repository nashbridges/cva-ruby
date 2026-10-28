# cva (Class Variance Authority)

This is a Ruby port of [cva.style](https://github.com/joe-bell/cva) JS library.
It is a tool for conditionally concatenating CSS classes.

The CVA (Class Variance Authority) pattern is based on the idea that there's
a limited number of states (variants) your CSS component can hold. Each state
is described with a CSS class or a set of classes. You then provide a set of
variants as an input, and get back a final list of CSS classes.

The library aims to be both CSS framework and view renderer agnostic. You can
use it with atomic CSS (Tailwind), entity-based CSS (BEM), in component based
rendering (ViewComponent, Phlex) or plain Rails/Hanami etc views.

It should not be confused with the general purpose CSS concatenators like
[clsx](https://github.com/svyatov/clsx-ruby) or Rails `class_names`. Those
accept raw CSS classes as an input, whereas this library requires you to work
with a limited number of design tokens (variants).

## Status

Production ready.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add cva-ruby
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install cva-ruby
```

## Usage

### ViewComponent

```ruby
# app/components/button_component.rb

class ButtonComponent < ViewComponent::Base
  # the helper generates `cva_class_name` method
  include Cva::ModelHelper.new(
    base: "button",
    variants: {
      intent: {
        primary: "button--primary",
        secondary: "button--secondary"
      }
    }
  )

  # calling `cva_class_name(intent: :primary)` returns "button button--primary"
  def initialize(title:, intent:)
    @title = title
    @class_name = cva_class_name(intent:)
  end
end
```

```erb
<% # app/components/button_component.html.erb %>

<button title="<%= @title %>" class="<%= @class_name %>">
  <%= content %>
</button>
```

```erb
<% # app/views/posts/index.html.erb %>

<%= render(ButtonComponent.new(title: "my title", intent: :primary)) do %>
  Hello, Button!
<% end %>
```

Rendering the view gets you:

```html
<button title="my title" class="button button--primary">
  Hello, Button!
</button>
```

### Plain views

```ruby
# config/initializers/cva.rb

class AppCva
  # default `cva_class_name` method name is overridden
  include Cva::ModelHelper.new(
    method_name: "button",
    base: "button",
    variants: {
      intent: {
        primary: "button--primary",
        secondary: "button--secondary"
      }
    }
  )

  # you can include as many as you need as long as method names do not collide
  include Cva::ModelHelper.new(
    method_name: "tooltip",
    base: "tooltip",
    variants: {
      position: {
        top: "tooltip--top",
        left: "tooltip--left"
      }
    }
  )
end
```

```ruby
# app/helpers/application_helper.rb

module ApplicationHelper
  # the method name can be anything really
  def cva
    @cva ||= AppCva.new
  end
end
```

```erb
<% # app/views/application/_button.html.erb %>

<button class="<%= cva.button(intent: :primary) %>">
  Oh hello!
</button>
```

### With Tailwind

When using Tailwind CSS, you will need a custom class merger that skips
conficting classes. Pick one of the existing libraries:

- https://github.com/abuisman/tail_merge
- https://github.com/gjtorikian/tailwind_merge

An example integration:

```ruby
# config/initializers/cva.rb

require "tail_merge"

class CvaTailwindMerger
  def call(classes)
    TailMerge.merge(classes)
  end
end

Cva::Config.merger_class = CvaTailwindMerger
```

## Documentation

Start with [Component](https://rubydoc.info/gems/cva-ruby/Cva/Component), then move
to [ModelHelper](https://rubydoc.info/gems/cva-ruby/Cva/ModelHelper).

## Similar works

- https://github.com/defvova/cva_rails
- https://github.com/palkan/view_component-contrib#style-variants

Compared to them, this library has less moving parts and no dependencies
(still, you will need a custom merger for usage with Tailwind).

The functionality is pretty much the same among all of the libraries.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bundle exec rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

See `bundle exec rake -T` for the list of all available commands.

## Issues

Use [Github issues](https://github.com/nashbridges/cva-ruby/issues) to file a ticket.

## Contributing

This project is open source and close contribution. I don't have mental
capacity to accept features I don't need.

You are still allowed to reuse and/or modify the code as you wish.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
