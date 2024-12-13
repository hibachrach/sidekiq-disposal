# frozen_string_literal: true

require "sidekiq/disposal/server_middleware"
require "sidekiq/disposal/client"

module Sidekiq
  module Disposal
    RSpec.describe ServerMiddleware, :with_test_redis do
      subject(:middleware) do
        described_class.new.tap { |m| m.config = ::Sidekiq.default_configuration }
      end

      let(:client) { Client.new }
      let(:serialized_job) do
        ServerMiddlewareTestCustomJob.perform_async("foo", 2, "baz")
        ServerMiddlewareTestCustomJob.jobs.first
      end

      it "raises JobKilled error if job has been marked to be killed" do
        Client.new.mark(:kill, :class, ServerMiddlewareTestCustomJob.name)
        expect do
          middleware.call(ServerMiddlewareTestCustomJob.new, serialized_job, "within_50_years") { :blah }
        end.to raise_error(JobKilled)
      end

      it "raises JobDropped error if job has been marked to be dropped" do
        Client.new.mark(:drop, :class, ServerMiddlewareTestCustomJob.name)
        expect do
          middleware.call(ServerMiddlewareTestCustomJob.new, serialized_job, "within_50_years") { :blah }
        end.to raise_error(JobDropped)
      end

      it "does not raise error if job has been marked but is non-disposable" do
        Client.new.mark(:drop, :class, ServerMiddlewareTestNonDisposableJob.name)
        expect do
          middleware.call(ServerMiddlewareTestNonDisposableJob.new, serialized_job, "within_50_years") { :blah }
        end.not_to raise_error
      end

      it "does not raise error if job has not been marked" do
        expect do
          middleware.call(ServerMiddlewareTestCustomJob.new, serialized_job, "within_50_years") { :blah }
        end.not_to raise_error
      end
    end

    class ServerMiddlewareTestCustomJob
      include ::Sidekiq::Job

      sidekiq_options queue: :within_50_years

      def perform(foo, bar, baz)
      end
    end

    class ServerMiddlewareTestNonDisposableJob
      include ::Sidekiq::Job

      sidekiq_options queue: :within_50_years, disposable: false

      def perform(foo, bar, baz)
      end
    end
  end
end
