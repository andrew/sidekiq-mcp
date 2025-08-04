# frozen_string_literal: true

require_relative "lib/sidekiq/mcp/version"

Gem::Specification.new do |spec|
  spec.name = "sidekiq-mcp"
  spec.version = Sidekiq::Mcp::VERSION
  spec.authors = ["Andrew Nesbitt"]
  spec.email = ["andrewnez@gmail.com"]

  spec.summary = "Sidekiq MCP server plugin for LLM integration"
  spec.description = "A Sidekiq plugin that provides an MCP (Model Context Protocol) server for LLMs to interact with Sidekiq queues, stats, and failed jobs"
  spec.homepage = "https://github.com/andrew/sidekiq-mcp"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/andrew/sidekiq-mcp"
  spec.metadata["changelog_uri"] = "https://github.com/andrew/sidekiq-mcp/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ example/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 6.0"
  spec.add_dependency "rack", ">= 2.0"
  spec.add_dependency "base64"
  spec.add_dependency "dry-schema", "~> 1.13"
  
  spec.add_development_dependency "rack-test"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
