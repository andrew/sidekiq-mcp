# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class RetryJobTool < Tool
        description "Retry a specific failed job by its JID"

        arguments do
          required(:jid).filled(:string)
        end

        def perform(jid:)
          retry_set = Sidekiq::RetrySet.new
          job = retry_set.find_job(jid)
          
          if job
            job.retry
            "Job #{jid} has been retried successfully"
          else
            "Job #{jid} not found in retry set"
          end
        end
      end
    end
  end
end