# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "github_changelog_generator/task"

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = "opus-codium"
  config.project = "riemann-rdap"
  config.exclude_labels = %w[dependencies skip-changelog]
  config.future_release = "v#{Riemann::Tools::Rdap::VERSION}"
end

require "standard/rake"

task default: %i[spec standard]
