# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class WorkersCountTool < Tool
        description "Show how many workers are running and busy"

        arguments do
          # No arguments needed
        end

        def perform
          processes = Sidekiq::ProcessSet.new
          
          total_workers = 0
          busy_workers = 0
          processes_info = []
          
          processes.each do |process|
            process_workers = process["concurrency"] || 0
            process_busy = process["busy"] || 0
            
            total_workers += process_workers
            busy_workers += process_busy
            
            processes_info << {
              hostname: process["hostname"],
              pid: process["pid"],
              concurrency: process_workers,
              busy: process_busy,
              utilization: process_workers > 0 ? ((process_busy.to_f / process_workers) * 100).round(2) : 0,
              started_at: process["started_at"]
            }
          end
          
          {
            total_processes: processes.size,
            total_workers: total_workers,
            busy_workers: busy_workers,
            idle_workers: total_workers - busy_workers,
            overall_utilization: total_workers > 0 ? ((busy_workers.to_f / total_workers) * 100).round(2) : 0,
            processes: processes_info
          }.to_json
        end
      end
    end
  end
end