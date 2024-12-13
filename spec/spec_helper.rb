# frozen_string_literal: true

if ENV["GITHUB_ACTIONS"].nil?
  require "debug"
end

require "sidekiq/disposal"
require "sidekiq/testing"
require_relative "support/test_redis_server"

# Initialize the Sidekiq client to use our test-specific Redis, rather than
# defaulting to redis://localhost:6379/0
Sidekiq.configure_client do |sk_config|
  sk_config.redis = {url: Sidekiq::Disposal::TestRedisServer.url}
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/rspec-status.txt"
  config.disable_monkey_patching!
  config.warnings = true

  # Do not abort on the first failure of an expectation within an example.
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    Sidekiq::Testing.fake!
    Sidekiq::Disposal::TestRedisServer.kill_zombies
  end

  config.before(:context, :with_test_redis) do
    Sidekiq::Disposal::TestRedisServer.start_if_not_running
  end

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  config.before(:each, :with_test_redis) do
    Sidekiq.redis(&:flushall)
  end

  config.after(:suite) do
    Sidekiq::Disposal::TestRedisServer.kill
  end
end
