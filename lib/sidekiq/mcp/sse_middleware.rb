# frozen_string_literal: true

require "rack"
require "base64"
require "json"
require "securerandom"

module Sidekiq
  module Mcp
    class SseMiddleware
      SSE_HEADERS = {
        'Content-Type' => 'text/event-stream',
        'Cache-Control' => 'no-cache, no-store, must-revalidate',
        'Connection' => 'keep-alive',
        'X-Accel-Buffering' => 'no', # For Nginx
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Access-Control-Allow-Headers' => 'Content-Type, Authorization',
        'Access-Control-Max-Age' => '86400',
        'Keep-Alive' => 'timeout=600',
        'Pragma' => 'no-cache',
        'Expires' => '0'
      }.freeze

      def initialize(app)
        @app = app
        @server = Server.new
        @clients = {}
        @clients_mutex = Mutex.new
      end

      def call(env)
        request = Rack::Request.new(env)
        
        return @app.call(env) unless sse_request?(request)
        return unauthorized_response unless authorized?(request)
        
        if request.get?
          handle_sse_connection(request, env)
        elsif request.post?
          handle_mcp_message(request)
        else
          method_not_allowed_response
        end
      end

      private

      def sse_request?(request)
        config = Sidekiq::Mcp.configuration || Sidekiq::Mcp::Configuration.new
        request.path == "#{config.path}/sse"
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
          encoded = auth_header.split(" ", 2).last
          decoded = Base64.decode64(encoded)
          _username, password = decoded.split(":", 2)
          password == config.auth_token
        else
          false
        end
      end

      def handle_sse_connection(request, env)
        client_id = SecureRandom.hex(8)
        
        [200, SSE_HEADERS, SseStreamer.new(client_id, self)]
      end

      def handle_mcp_message(request)
        body = request.body.read
        response = @server.handle_request(body)
        
        # Broadcast to all SSE clients
        broadcast_to_clients(response) if response
        
        if response.nil?
          [204, {}, []]
        else
          [200, {"Content-Type" => "application/json"}, [response.to_json]]
        end
      end

      def broadcast_to_clients(message)
        @clients_mutex.synchronize do
          @clients.each_value do |client_data|
            begin
              client_data[:stream].write("data: #{message.to_json}\n\n")
              client_data[:stream].flush
            rescue
              # Client disconnected, will be cleaned up later
            end
          end
        end
      end

      def add_client(client_id, stream)
        @clients_mutex.synchronize do
          @clients[client_id] = { stream: stream, connected_at: Time.now }
        end
      end

      def remove_client(client_id)
        @clients_mutex.synchronize do
          @clients.delete(client_id)
        end
      end

      def unauthorized_response
        [401, { "Content-Type" => "application/json" }, [{ error: "Unauthorized" }.to_json]]
      end

      def method_not_allowed_response
        [405, { "Content-Type" => "application/json" }, [{ error: "Method not allowed" }.to_json]]
      end

      class SseStreamer
        def initialize(client_id, middleware)
          @client_id = client_id
          @middleware = middleware
        end

        def each
          @middleware.add_client(@client_id, self)
          
          # Send initial connection message
          yield "data: #{initial_message.to_json}\n\n"
          
          # Keep connection alive with heartbeats
          begin
            loop do
              sleep 30
              yield ": heartbeat\n\n"
            end
          rescue
            # Connection closed
          ensure
            @middleware.remove_client(@client_id)
          end
        end

        def write(data)
          @data = data
        end

        def flush
          # This method is called by broadcast_to_clients
          # In a real streaming setup, we'd need to queue messages
          # For now, this is a simplified implementation
        end

        private

        def initial_message
          {
            jsonrpc: "2.0",
            method: "connection/established",
            params: {
              client_id: @client_id,
              server_info: {
                name: "sidekiq-mcp",
                version: Sidekiq::Mcp::VERSION
              }
            }
          }
        end
      end
    end
  end
end