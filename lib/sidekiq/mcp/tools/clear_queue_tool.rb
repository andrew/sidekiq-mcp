# frozen_string_literal: true

require_relative "../tool"
require "sidekiq/api"

module Sidekiq
  module Mcp
    module Tools
      class ClearQueueTool < Tool
        description "Clear all jobs from a specific queue (destructive operation)"

        arguments do
          required(:queue_name).filled(:string)
        end

        def perform(queue_name:)
          queue = Sidekiq::Queue.new(queue_name)
          initial_size = queue.size
          
          if initial_size == 0
            "Queue '#{queue_name}' is already empty"
          else
            queue.clear
            "Cleared #{initial_size} jobs from queue '#{queue_name}'"
          end
        end
      end
    end
  end
end