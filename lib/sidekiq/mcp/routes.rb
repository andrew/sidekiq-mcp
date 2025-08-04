# frozen_string_literal: true

module Sidekiq
  module Mcp
    class Routes
      def self.mount(app, path: "/sidekiq-mcp")
        # Configure the MCP path
        Sidekiq::Mcp.configure do |config|
          config.path = path
        end
        
        # Add the middleware to the Rack stack
        app.use Sidekiq::Mcp::Middleware
      end
    end
  end
end