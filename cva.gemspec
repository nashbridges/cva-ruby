# frozen_string_literal: true

require_relative "lib/cva/version"

Gem::Specification.new do |spec|
  spec.name = "cva-ruby"
  spec.version = Cva::VERSION
  spec.authors = ["Andrii Malyshko"]
  spec.email = ["pleasesendmeaspam@gmail.com"]

  spec.summary = "A tool for conditionally concatenating CSS classes"
  spec.description = <<~DESCRIPTION
    This is a Ruby port of cva.style JS library. The CVA (Class Variance Authority)
    pattern is based on the idea that there's a limited number of states
    (variants) your CSS component can hold. Each state is described with a CSS
    class or a set of classes. You then provide a set of variants as an input,
    and get back a final list of CSS classes.
  DESCRIPTION
  spec.homepage = "https://github.com/nashbridges/cva-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/nashbridges/cva-ruby/blob/master/CHANGELOG.md"

  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
