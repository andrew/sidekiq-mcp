# frozen_string_literal: true

Sidekiq::Mcp.configure do |config|
  config.enabled = true
  config.path = "/sidekiq-mcp"
  config.auth_token = Rails.application.credentials.sidekiq_mcp_token || "development-token-123"
end