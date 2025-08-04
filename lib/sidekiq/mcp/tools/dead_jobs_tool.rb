# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class DeadJobsTool < Tool
        description "Show jobs in the dead set (jobs that have exhausted all retries)"

        arguments do
          optional(:limit).filled(:integer).value(gteq?: 1, lteq?: 100)
        end

        def perform(limit: 10)
          jobs = Sidekiq::DeadSet.new.first(limit).map do |job|
            {
              jid: job.jid,
              class: job.klass,
              args: job.args,
              queue: job.queue,
              error_message: job["error_message"],
              error_class: job["error_class"],
              failed_at: job["failed_at"],
              retry_count: job["retry_count"],
              died_at: job["died_at"]
            }
          end
          
          {
            total_size: Sidekiq::DeadSet.new.size,
            jobs: jobs
          }.to_json
        end
      end
    end
  end
end