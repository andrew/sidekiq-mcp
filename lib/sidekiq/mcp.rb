# frozen_string_literal: true

require_relative "mcp/version"
require_relative "mcp/tool"
require_relative "mcp/server"
require_relative "mcp/tools"
require_relative "mcp/middleware"
require_relative "mcp/sse_middleware"
require_relative "mcp/routes"

# Load all tool classes
Dir[File.join(__dir__, "mcp/tools/*.rb")].each { |file| require file }

if defined?(::Rails::Railtie)
  require_relative "mcp/railtie"
end

module Sidekiq
  module Mcp
    class Error < StandardError; end
    
    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    class Configuration
      attr_accessor :enabled, :path, :auth_token, :sse_enabled

      def initialize
        @enabled = true
        @path = "/sidekiq-mcp"
        @auth_token = nil
        @sse_enabled = true
      end
    end
  end
end
