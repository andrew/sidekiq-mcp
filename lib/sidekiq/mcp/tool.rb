# frozen_string_literal: true

require "dry-schema"

module Sidekiq
  module Mcp
    class Tool
      class << self
        attr_accessor :tool_description, :argument_schema

        def description(text)
          @tool_description = text
        end

        def arguments(&block)
          @argument_schema = Dry::Schema.Params(&block) if block_given?
        end

        def schema_to_json_schema
          return { type: "object", properties: {}, required: [] } unless @argument_schema

          # For now, return a simple schema - can be enhanced later
          {
            type: "object",
            properties: {},
            required: []
          }
        end
      end

      def self.to_tool_definition
        tool_name = name.split("::").last.gsub(/Tool$/, "").gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, "")
        {
          name: tool_name,
          description: @tool_description || "#{name} tool",
          inputSchema: schema_to_json_schema
        }
      end

      def call(**args)
        # Validate arguments if schema is defined
        if self.class.argument_schema
          result = self.class.argument_schema.call(args)
          raise ArgumentError, "Invalid arguments: #{result.errors.to_h}" unless result.success?
          args = result.to_h
        end

        perform(**args)
      end

      def perform(**args)
        raise NotImplementedError, "Subclasses must implement #perform"
      end
    end
  end
end