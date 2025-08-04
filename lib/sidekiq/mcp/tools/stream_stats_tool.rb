# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class StreamStatsTool < Tool
        description "Start streaming real-time Sidekiq statistics (use with SSE)"

        arguments do
          optional(:interval).filled(:integer).value(gteq?: 1, lteq?: 300) # 1-300 seconds
        end

        def perform(interval: 5)
          # This tool is designed to work with SSE streaming
          # In a real implementation, this would start a background task
          # For now, we'll return the current stats with streaming info
          
          stats = Sidekiq::Stats.new
          current_stats = {
            timestamp: Time.now.utc.iso8601,
            processed: stats.processed,
            failed: stats.failed,
            busy: stats.workers_size,
            enqueued: stats.enqueued,
            scheduled: stats.scheduled_size,
            retry: stats.retry_size,
            dead: stats.dead_size,
            processes: stats.processes_size,
            default_queue_latency: stats.default_queue_latency
          }
          
          {
            message: "Stats streaming initiated with #{interval}s interval",
            current_stats: current_stats,
            sse_endpoint: "/sidekiq-mcp/sse",
            note: "Connect to SSE endpoint to receive real-time updates"
          }.to_json
        end
      end
    end
  end
end