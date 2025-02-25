# frozen_string_literal: true

require_relative "lib/arf/version"

Gem::Specification.new do |spec|
  spec.name = "arf"
  spec.version = Arf::VERSION
  spec.authors = ["Vito Sartori"]
  spec.email = ["hey@vito.io"]

  spec.summary = "arf stands for Another RPC Framework"
  spec.description = "Opinionated RPC framework for inter-process, inter-application communication"
  spec.homepage = "https://github.com/arf-rpc/arf-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/arf-rpc/arf-ruby/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile .editorconfig .rspec .rubocop.yml]) ||
        f.end_with?(".md")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby", "~> 1.3"
  spec.add_dependency "logrb", "~> 0.1.5"
  spec.add_dependency "nio4r", "~> 2.7"
  spec.add_dependency "zlib", "~> 3.2"
  spec.metadata["rubygems_mfa_required"] = "true"
end
