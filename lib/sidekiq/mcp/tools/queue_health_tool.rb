# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class QueueHealthTool < Tool
        description "Heuristics on whether queues are backed up or healthy"

        arguments do
          optional(:latency_threshold).filled(:integer).value(gteq?: 1)
          optional(:size_threshold).filled(:integer).value(gteq?: 1)
        end

        def perform(latency_threshold: 60, size_threshold: 100)
          queues_health = Sidekiq::Queue.all.map do |queue|
            latency = queue.latency
            size = queue.size
            
            # Determine health status
            health_issues = []
            health_issues << "High latency (#{latency.round(2)}s)" if latency > latency_threshold
            health_issues << "Large queue size (#{size} jobs)" if size > size_threshold
            
            health_status = health_issues.empty? ? "healthy" : "warning"
            health_status = "critical" if health_issues.size > 1
            
            {
              name: queue.name,
              size: size,
              latency: latency.round(2),
              health_status: health_status,
              issues: health_issues,
              recommendations: generate_recommendations(health_issues, size, latency)
            }
          end
          
          overall_health = queues_health.any? { |q| q[:health_status] == "critical" } ? "critical" : 
                          queues_health.any? { |q| q[:health_status] == "warning" } ? "warning" : "healthy"
          
          {
            overall_health: overall_health,
            thresholds: {
              latency_threshold: latency_threshold,
              size_threshold: size_threshold
            },
            queues: queues_health
          }.to_json
        end

        private

        def generate_recommendations(issues, size, latency)
          recommendations = []
          
          if issues.any? { |i| i.include?("latency") }
            recommendations << "Consider adding more workers or optimizing job performance"
          end
          
          if issues.any? { |i| i.include?("size") }
            recommendations << "Queue is backing up - check for worker issues or increase concurrency"
          end
          
          if size > 1000
            recommendations << "Very large queue - consider splitting into smaller queues or adding priority"
          end
          
          if latency > 300
            recommendations << "Extremely high latency - immediate attention required"
          end
          
          recommendations
        end
      end
    end
  end
end