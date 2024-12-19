# frozen_string_literal: true

require_relative "lib/sidekiq/disposal/version"

Gem::Specification.new do |spec|
  spec.name = "sidekiq-disposal"
  spec.version = Sidekiq::Disposal::VERSION
  spec.authors = ["Hazel Bachrach", "Steven Harman"]
  spec.email = ["dacheatbot@gmail.com", "steven@harmanly.com"]

  spec.summary = "A mechanism to dispose of (cancel) queued jobs by Job ID, Batch ID, or Job Class."
  spec.description = <<~DESC
    A mechanism to mark Sidekiq Jobs to be disposed of by Job ID, Batch ID, or Job Class.
    Disposal here means to either `:kill` the Job (send to the Dead queue) or `:discard` it (throw it away), at the time the job is picked up and processed by Sidekiq.
  DESC
  spec.homepage = "https://github.com/hibachrach/sidekiq-disposal"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata = {
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "documentation_uri" => spec.homepage,
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ spec/ .git .github Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", "~> 7.0"
end
