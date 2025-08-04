# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class ProcessSetTool < Tool
        description "Get detailed information about all Sidekiq processes/workers"

        arguments do
          # No arguments needed
        end

        def perform
          processes = Sidekiq::ProcessSet.new.map do |process|
            {
              identity: process["identity"],
              hostname: process["hostname"],
              pid: process["pid"],
              tag: process["tag"],
              concurrency: process["concurrency"],
              queues: process["queues"],
              busy: process["busy"],
              beat: process["beat"],
              quiet: process["quiet"],
              started_at: process["started_at"],
              labels: process["labels"],
              version: process["version"],
              rss_kb: process["rss"]
            }
          end
          
          {
            total_processes: processes.size,
            processes: processes
          }.to_json
        end
      end
    end
  end
end