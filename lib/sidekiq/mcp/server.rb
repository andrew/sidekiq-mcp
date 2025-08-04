# frozen_string_literal: true

require "json"

module Sidekiq
  module Mcp
    class Server
      PROTOCOL_VERSION = "2025-06-18"

      def initialize
        @tools = ToolsRegistry.new
      end

      def handle_request(body)
        request = JSON.parse(body)
        
        case request["method"]
        when "initialize"
          handle_initialize(request)
        when "tools/list"
          handle_tools_list(request)
        when "tools/call"
          handle_tools_call(request)
        when "notifications/initialized"
          handle_initialized(request)
        else
          error_response(request["id"], -32601, "Method not found")
        end
      rescue JSON::ParserError
        error_response(nil, -32700, "Parse error")
      rescue => e
        error_response(request&.dig("id"), -32603, "Internal error: #{e.message}")
      end

      private

      def handle_initialize(request)
        {
          jsonrpc: "2.0",
          id: request["id"],
          result: {
            protocolVersion: PROTOCOL_VERSION,
            capabilities: {
              tools: {}
            },
            serverInfo: {
              name: "sidekiq-mcp",
              version: Sidekiq::Mcp::VERSION
            }
          }
        }
      end

      def handle_tools_list(request)
        {
          jsonrpc: "2.0",
          id: request["id"],
          result: {
            tools: @tools.list
          }
        }
      end

      def handle_tools_call(request)
        tool_name = request.dig("params", "name")
        arguments = request.dig("params", "arguments") || {}
        
        result = @tools.call(tool_name, arguments)
        
        {
          jsonrpc: "2.0",
          id: request["id"],
          result: {
            content: [
              {
                type: "text",
                text: result
              }
            ]
          }
        }
      end

      def handle_initialized(request)
        # No response needed for notifications
        nil
      end

      def error_response(id, code, message)
        {
          jsonrpc: "2.0",
          id: id,
          error: {
            code: code,
            message: message
          }
        }
      end
    end
  end
end