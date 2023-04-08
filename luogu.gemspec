# frozen_string_literal: true

require_relative "lib/luogu/version"

Gem::Specification.new do |spec|
  spec.name = "luogu"
  spec.version = Luogu::VERSION
  spec.authors = ["MJ"]
  spec.email = ["tywf91@gmail.com"]

  spec.summary = "luogu 用于 Prompt 工程开发"
  spec.description = "使用markdown来快速实现 Prompt工程研发"
  spec.homepage = "https://github.com/mjason/luogu"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mjason/luogu"
  spec.metadata["changelog_uri"] = "https://github.com/mjason/luogu"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'ruby-openai', '~> 3.7'
  spec.add_dependency 'dotenv', '~> 2.8', '>= 2.8.1'
  spec.add_dependency 'tty-prompt', '~> 0.23.1'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
