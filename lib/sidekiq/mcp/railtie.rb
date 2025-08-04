# frozen_string_literal: true

require "rails/railtie"

module Sidekiq
  module Mcp
    class Railtie < ::Rails::Railtie
      railtie_name :sidekiq_mcp

      initializer "sidekiq_mcp.middleware" do |app|
        # Auto-configure if in Rails environment
        app.config.middleware.use Sidekiq::Mcp::Middleware
        
        # Add SSE middleware if enabled
        if Sidekiq::Mcp.configuration&.sse_enabled != false
          app.config.middleware.use Sidekiq::Mcp::SseMiddleware
        end
      end
    end
  end
end