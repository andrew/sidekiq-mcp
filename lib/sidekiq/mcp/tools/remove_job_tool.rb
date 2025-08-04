# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class RemoveJobTool < Tool
        description "Remove a job from any set (queue/schedule/retry/dead) by JID"

        arguments do
          required(:jid).filled(:string)
        end

        def perform(jid:)
          # Try to find and remove from retry set
          retry_set = Sidekiq::RetrySet.new
          if (job = retry_set.find_job(jid))
            job.delete
            return "Job #{jid} removed from retry set"
          end
          
          # Try to find and remove from scheduled set
          scheduled_set = Sidekiq::ScheduledSet.new
          if (job = scheduled_set.find_job(jid))
            job.delete
            return "Job #{jid} removed from scheduled set"
          end
          
          # Try to find and remove from dead set
          dead_set = Sidekiq::DeadSet.new
          if (job = dead_set.find_job(jid))
            job.delete
            return "Job #{jid} removed from dead set"
          end
          
          # Try to find and remove from queues
          Sidekiq::Queue.all.each do |queue|
            if (job = queue.find_job(jid))
              job.delete
              return "Job #{jid} removed from queue '#{queue.name}'"
            end
          end
          
          "Job #{jid} not found in any queue or set"
        end
      end
    end
  end
end