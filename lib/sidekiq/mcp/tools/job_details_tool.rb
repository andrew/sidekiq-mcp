# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class JobDetailsTool < Tool
        description "Show args, error message, and history for a job by JID (failed, scheduled, or retry)"

        arguments do
          required(:jid).filled(:string)
        end

        def perform(jid:)
          job = find_job_by_jid(jid)
          
          return "Job #{jid} not found" unless job
          
          details = {
            jid: job.jid,
            class: job.klass,
            args: job.args,
            queue: job.queue,
            created_at: job.created_at,
            enqueued_at: job.enqueued_at
          }
          
          # Add retry/failure specific info
          if job.respond_to?(:[])
            details[:error_message] = job["error_message"] if job["error_message"]
            details[:error_class] = job["error_class"] if job["error_class"]
            details[:failed_at] = job["failed_at"] if job["failed_at"]
            details[:retry_count] = job["retry_count"] if job["retry_count"]
            details[:retried_at] = job["retried_at"] if job["retried_at"]
            details[:backtrace] = job["error_backtrace"] if job["error_backtrace"]
          end
          
          # Add scheduled info
          if job.respond_to?(:at)
            details[:scheduled_at] = job.at
          end
          
          details.to_json
        end

        private

        def find_job_by_jid(jid)
          # Check retry set
          job = Sidekiq::RetrySet.new.find_job(jid)
          return job if job
          
          # Check scheduled set
          job = Sidekiq::ScheduledSet.new.find_job(jid)
          return job if job
          
          # Check dead set
          job = Sidekiq::DeadSet.new.find_job(jid)
          return job if job
          
          # Check all queues
          Sidekiq::Queue.all.each do |queue|
            job = queue.find_job(jid)
            return job if job
          end
          
          nil
        end
      end
    end
  end
end