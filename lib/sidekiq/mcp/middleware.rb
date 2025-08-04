# frozen_string_literal: true

require "rack"
require "base64"

module Sidekiq
  module Mcp
    class Middleware
      def initialize(app)
        @app = app
        @server = Server.new
      end

      def call(env)
        request = Rack::Request.new(env)
        
        return @app.call(env) unless mcp_request?(request)
        return unauthorized_response unless authorized?(request)
        
        if request.post?
          handle_mcp_request(request)
        else
          method_not_allowed_response
        end
      end

      private

      def mcp_request?(request)
        config = Sidekiq::Mcp.configuration || Sidekiq::Mcp::Configuration.new
        request.path == config.path
      end

      def authorized?(request)
        config = Sidekiq::Mcp.configuration || Sidekiq::Mcp::Configuration.new
        
        return true unless config.auth_token
        
        auth_header = request.env["HTTP_AUTHORIZATION"]
        return false unless auth_header
        
        if auth_header.start_with?("Bearer ")
          token = auth_header.split(" ", 2).last
          token == config.auth_token
        elsif auth_header.start_with?("Basic ")
          # For Basic auth, expect username to be anything and password to be the token
          encoded = auth_header.split(" ", 2).last
          decoded = Base64.decode64(encoded)
          _username, password = decoded.split(":", 2)
          password == config.auth_token
        else
          false
        end
      end

      def handle_mcp_request(request)
        body = request.body.read
        response = @server.handle_request(body)
        
        return no_content_response if response.nil?
        
        [
          200,
          {
            "Content-Type" => "application/json",
            "Access-Control-Allow-Origin" => "*",
            "Access-Control-Allow-Methods" => "POST, OPTIONS",
            "Access-Control-Allow-Headers" => "Content-Type, Authorization"
          },
          [response.to_json]
        ]
      rescue => e
        error_response(e.message)
      end

      def unauthorized_response
        [
          401,
          { "Content-Type" => "application/json" },
          [{ error: "Unauthorized" }.to_json]
        ]
      end

      def method_not_allowed_response
        [
          405,
          { "Content-Type" => "application/json" },
          [{ error: "Method not allowed" }.to_json]
        ]
      end

      def no_content_response
        [204, {}, []]
      end

      def error_response(message)
        [
          500,
          { "Content-Type" => "application/json" },
          [{ error: "Internal server error: #{message}" }.to_json]
        ]
      end
    end
  end
end