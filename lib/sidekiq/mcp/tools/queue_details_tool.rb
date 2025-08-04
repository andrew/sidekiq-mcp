# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class QueueDetailsTool < Tool
        description "Get detailed information about a specific queue including jobs"

        arguments do
          required(:queue_name).filled(:string)
          optional(:limit).filled(:integer).value(gteq?: 1, lteq?: 100)
        end

        def perform(queue_name:, limit: 10)
          queue = Sidekiq::Queue.new(queue_name)
          jobs = queue.first(limit).map do |job|
            {
              jid: job.jid,
              class: job.klass,
              args: job.args,
              created_at: job.created_at,
              enqueued_at: job.enqueued_at,
              queue: job.queue
            }
          end
          
          {
            queue_name: queue_name,
            size: queue.size,
            latency: queue.latency,
            jobs: jobs
          }.to_json
        end
      end
    end
  end
end