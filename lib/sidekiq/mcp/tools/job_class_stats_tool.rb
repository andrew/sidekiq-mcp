# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class JobClassStatsTool < Tool
        description "Breakdown of job counts, retries, and error rates by class"

        arguments do
          # No arguments needed
        end

        def perform
          stats = {}
          
          # Get stats from retry set
          Sidekiq::RetrySet.new.each do |job|
            klass = job.klass
            stats[klass] ||= { retry_count: 0, failed_count: 0, total_retries: 0 }
            stats[klass][:retry_count] += 1
            stats[klass][:total_retries] += (job["retry_count"] || 0)
          end
          
          # Get stats from dead set
          Sidekiq::DeadSet.new.each do |job|
            klass = job.klass
            stats[klass] ||= { retry_count: 0, failed_count: 0, total_retries: 0 }
            stats[klass][:failed_count] += 1
          end
          
          # Get stats from queues
          Sidekiq::Queue.all.each do |queue|
            queue.each do |job|
              klass = job.klass
              stats[klass] ||= { retry_count: 0, failed_count: 0, total_retries: 0, enqueued_count: 0 }
              stats[klass][:enqueued_count] = (stats[klass][:enqueued_count] || 0) + 1
            end
          end
          
          # Calculate error rates
          stats.each do |klass, data|
            total_jobs = (data[:retry_count] || 0) + (data[:failed_count] || 0) + (data[:enqueued_count] || 0)
            error_count = (data[:retry_count] || 0) + (data[:failed_count] || 0)
            data[:error_rate] = total_jobs > 0 ? (error_count.to_f / total_jobs * 100).round(2) : 0
            data[:total_jobs] = total_jobs
          end
          
          stats.to_json
        end
      end
    end
  end
end