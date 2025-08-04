# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class SidekiqStatsTool < Tool
        description "Get general Sidekiq statistics including processed, failed, busy, enqueued counts"

        arguments do
          # No arguments needed for general stats
        end

        def perform
          stats = Sidekiq::Stats.new
          {
            processed: stats.processed,
            failed: stats.failed,
            busy: stats.workers_size,
            enqueued: stats.enqueued,
            scheduled: stats.scheduled_size,
            retry: stats.retry_size,
            dead: stats.dead_size,
            default_queue_latency: stats.default_queue_latency
          }.to_json
        end
      end
    end
  end
end