# frozen_string_literal: true

require_relative "lib/awaaz/version"

Gem::Specification.new do |spec|
  spec.name = "awaaz"
  spec.version = Awaaz::VERSION
  spec.authors = ["Saad Azam"]
  spec.email = ["zeroinside4u@gmail.com"]

  spec.summary = "Audio Analysis with Ruby"
  spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/SadMadLad/awaaz"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.2"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/SadMadLad/awaaz"
  spec.metadata["changelog_uri"] = "https://github.com/SadMadLad/awaaz/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "ffi", "~> 1.17.2"
  spec.add_dependency "numo-narray", "~> 0.9.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
