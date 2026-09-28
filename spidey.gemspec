# frozen_string_literal: true

require_relative "lib/spidey/version"

Gem::Specification.new do |spec|
  spec.name    = "spidey"
  spec.version = Spidey::VERSION
  spec.summary = "Your friendly neighbourhood web crawler 🕷"
  spec.description = <<~DESC
    Spidey is a modern, dependency-light Ruby web-crawler gem.
    Include it in any class, register starting URLs, define processors,
    and crawl the web with ease. Works standalone or with ActiveJob.
  DESC

  spec.license  = "MIT"
  spec.homepage = "https://github.com/Parths-29/Spidey"

  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata = {
    "homepage_uri"    => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri"   => "#{spec.homepage}/releases",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"].reject { |f| File.directory?(f) }
  end

  spec.bindir        = "exe"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.15"

  spec.add_development_dependency "rspec",    "~> 3.12"
  spec.add_development_dependency "webmock",  "~> 3.0"
  spec.add_development_dependency "rake",     "~> 13.0"
end
