# frozen_string_literal: true

require "rails/railtie"

module Sidekiq
  module Mcp
    class Railtie < Rails::Railtie
      railtie_name :sidekiq_mcp

      config.after_initialize do
        # Auto-configure if in Rails environment
        Rails.application.config.middleware.use Sidekiq::Mcp::Middleware
        
        # Add SSE middleware if enabled
        if Sidekiq::Mcp.configuration&.sse_enabled != false
          Rails.application.config.middleware.use Sidekiq::Mcp::SseMiddleware
        end
      end
    end
  end
end