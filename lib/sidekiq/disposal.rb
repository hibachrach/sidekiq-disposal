# frozen_string_literal: true

require_relative "disposal/version"
require_relative "disposal/client"
require_relative "disposal/server_middleware"

module Sidekiq
  # Namespace for everything related to job disposal: the process of putting
  # jobs' markers (i.e. identifying features) on a list so they can be "killed"
  # (sent immediately to dead set/morgue) or "discarded" (completely discarded
  # from Sidekiq) when picked up from the queue.
  module Disposal
    Error = Class.new(StandardError)
    JobKilled = Class.new(Error)
    JobDiscarded = Class.new(Error)
  end
end
