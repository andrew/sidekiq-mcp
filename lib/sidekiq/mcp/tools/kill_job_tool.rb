# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class KillJobTool < Tool
        description "Move a job from retry/scheduled set to the dead set"

        arguments do
          required(:jid).filled(:string)
        end

        def perform(jid:)
          # Try retry set first
          retry_set = Sidekiq::RetrySet.new
          job = retry_set.find_job(jid)
          
          if job
            job.kill
            return "Job #{jid} moved from retry set to dead set"
          end
          
          # Try scheduled set
          scheduled_set = Sidekiq::ScheduledSet.new
          job = scheduled_set.find_job(jid)
          
          if job
            job.kill
            return "Job #{jid} moved from scheduled set to dead set"
          end
          
          "Job #{jid} not found in retry or scheduled sets"
        end
      end
    end
  end
end