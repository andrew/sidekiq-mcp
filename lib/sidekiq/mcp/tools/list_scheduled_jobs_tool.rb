# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class ListScheduledJobsTool < Tool
        description "List jobs in the scheduled set"

        arguments do
          optional(:limit).filled(:integer).value(gteq?: 1, lteq?: 100)
        end

        def perform(limit: 10)
          jobs = Sidekiq::ScheduledSet.new.first(limit).map do |job|
            {
              jid: job.jid,
              class: job.klass,
              args: job.args,
              queue: job.queue,
              scheduled_at: job.at,
              created_at: job.created_at
            }
          end
          
          {
            total_size: Sidekiq::ScheduledSet.new.size,
            jobs: jobs
          }.to_json
        end
      end
    end
  end
end