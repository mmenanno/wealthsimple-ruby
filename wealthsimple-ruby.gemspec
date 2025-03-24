# frozen_string_literal: true

require_relative "lib/wealthsimple/version"

Gem::Specification.new do |spec|
  spec.name          = "wealthsimple-ruby"
  spec.version       = WealthSimple::VERSION
  spec.author        = "@mmenanno"

  spec.summary       = "A Ruby wrapper for the WealthSimple API"
  spec.description   = "A Ruby gem that provides a clean interface to interact with the WealthSimple API"
  spec.homepage      = "https://github.com/mmenanno/wealthsimple-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("activesupport", ">= 6.1")
  spec.add_dependency("faraday", ">= 1.0.0")
  spec.add_dependency("sorbet-runtime", ">= 0.5")
end
