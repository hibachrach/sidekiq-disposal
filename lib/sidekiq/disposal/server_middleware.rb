# frozen_string_literal: true

require "sidekiq"
require_relative "../disposal"

module Sidekiq
  module Disposal
    class ServerMiddleware
      include ::Sidekiq::ServerMiddleware

      def initialize(client = Client.new)
        @client = client
      end

      def call(job_instance, job, _queue)
        if job_instance && !job_instance.class.get_sidekiq_options.fetch("disposable", true)
          yield
        elsif (disposal_method = client.target_disposal_method(job))
          case disposal_method
          when :kill
            raise JobKilled
          when :drop
            raise JobDropped
          end
        else
          yield
        end
      end

      private

      attr_reader :client
    end
  end
end
