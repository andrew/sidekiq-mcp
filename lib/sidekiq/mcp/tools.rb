# frozen_string_literal: true

module Sidekiq
  module Mcp
    module Tools
    end
    
    class ToolsRegistry
      def initialize
        register_all_tools
      end

      def list
        @tools.values
      end

      def call(tool_name, arguments)
        tool_class = @tool_classes[tool_name]
        return "Unknown tool: #{tool_name}" unless tool_class
        
        begin
          tool_instance = tool_class.new
          tool_instance.call(**arguments.transform_keys(&:to_sym))
        rescue => e
          "Error executing tool #{tool_name}: #{e.message}"
        end
      end

      private

      def register_all_tools
        @tools = {}
        @tool_classes = {}
        
        # Auto-discover all tool classes
        tool_classes = [
          Tools::SidekiqStatsTool,
          Tools::QueueDetailsTool,
          Tools::RetryJobTool,
          Tools::FailedJobsTool,
          Tools::JobClassStatsTool,
          Tools::JobDetailsTool,
          Tools::ListScheduledJobsTool,
          Tools::ListRetryJobsTool,
          Tools::DeadJobsTool,
          Tools::WorkersCountTool,
          Tools::QueueHealthTool,
          Tools::RemoveJobTool,
          Tools::ClearQueueTool,
          Tools::RescheduleJobTool,
          Tools::KillJobTool,
          Tools::ProcessSetTool,
          Tools::StreamStatsTool
        ]
        
        # Also register original legacy tools
        register_legacy_tools
        
        tool_classes.each do |tool_class|
          tool_def = tool_class.to_tool_definition
          @tools[tool_def[:name]] = tool_def
          @tool_classes[tool_def[:name]] = tool_class
        end
      end
      
      def register_legacy_tools
        # List queues tool
        @tools["list_queues"] = {
          name: "list_queues",
          description: "List all Sidekiq queues with their sizes and latency information",
          inputSchema: {
            type: "object",
            properties: {},
            required: []
          }
        }
        @tool_classes["list_queues"] = Class.new(Tool) do
          def perform
            queues = Sidekiq::Queue.all.map do |queue|
              {
                name: queue.name,
                size: queue.size,
                latency: queue.latency
              }
            end
            queues.to_json
          end
        end
        
        # Busy workers tool  
        @tools["busy_workers"] = {
          name: "busy_workers",
          description: "List currently busy workers and their job details",
          inputSchema: {
            type: "object",
            properties: {},
            required: []
          }
        }
        @tool_classes["busy_workers"] = Class.new(Tool) do
          def perform
            workers = Sidekiq::Workers.new.map do |process_id, thread_id, work|
              {
                process_id: process_id,
                thread_id: thread_id,
                queue: work["queue"],
                class: work["payload"]["class"],
                args: work["payload"]["args"],
                jid: work["payload"]["jid"],
                run_at: work["run_at"]
              }
            end
            workers.to_json
          end
        end

        # Delete failed job tool
        @tools["delete_failed_job"] = {
          name: "delete_failed_job",
          description: "Delete a specific failed job by its JID",
          inputSchema: {
            type: "object",
            properties: {
              jid: {
                type: "string",
                description: "Job ID of the failed job to delete"
              }
            },
            required: ["jid"]
          }
        }
        @tool_classes["delete_failed_job"] = Class.new(Tool) do
          def perform(jid:)
            retry_set = Sidekiq::RetrySet.new
            job = retry_set.find_job(jid)
            
            if job
              job.delete
              "Job #{jid} has been deleted successfully"
            else
              "Job #{jid} not found in retry set"
            end
          end
        end
      end
    end
  end
end