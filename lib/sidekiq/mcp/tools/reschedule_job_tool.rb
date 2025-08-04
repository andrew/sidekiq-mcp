# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class RescheduleJobTool < Tool
        description "Reschedule a job in the scheduled set to a new time"

        arguments do
          required(:jid).filled(:string)
          required(:new_time).filled(:string) # ISO 8601 format
        end

        def perform(jid:, new_time:)
          begin
            new_timestamp = Time.parse(new_time)
          rescue ArgumentError
            return "Invalid time format. Please use ISO 8601 format (e.g., '2024-12-25T10:00:00Z')"
          end
          
          scheduled_set = Sidekiq::ScheduledSet.new
          job = scheduled_set.find_job(jid)
          
          if job
            old_time = job.at
            job.reschedule(new_timestamp)
            "Job #{jid} rescheduled from #{old_time} to #{new_timestamp}"
          else
            "Job #{jid} not found in scheduled set"
          end
        end
      end
    end
  end
end