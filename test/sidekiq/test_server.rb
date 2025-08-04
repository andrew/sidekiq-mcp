# frozen_string_literal: true

require "test_helper"

class TestServer < Minitest::Test
  def setup
    @server = Sidekiq::Mcp::Server.new
  end

  def test_initialize_request
    request = {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "initialize",
      "params" => {}
    }

    response = @server.handle_request(request.to_json)
    
    assert_equal "2.0", response[:jsonrpc]
    assert_equal 1, response[:id]
    assert_equal "2025-06-18", response[:result][:protocolVersion]
    assert_equal "sidekiq-mcp", response[:result][:serverInfo][:name]
  end

  def test_tools_list_request
    request = {
      "jsonrpc" => "2.0",
      "id" => 2,
      "method" => "tools/list"
    }

    response = @server.handle_request(request.to_json)
    
    assert_equal "2.0", response[:jsonrpc]
    assert_equal 2, response[:id]
    assert_instance_of Array, response[:result][:tools]
    assert response[:result][:tools].length > 0
  end

  def test_tools_call_request
    request = {
      "jsonrpc" => "2.0",
      "id" => 3,
      "method" => "tools/call",
      "params" => {
        "name" => "sidekiq_stats",
        "arguments" => {}
      }
    }

    response = @server.handle_request(request.to_json)
    
    assert_equal "2.0", response[:jsonrpc]
    assert_equal 3, response[:id]
    assert_instance_of Array, response[:result][:content]
    assert_equal "text", response[:result][:content][0][:type]
  end

  def test_unknown_method
    request = {
      "jsonrpc" => "2.0",
      "id" => 4,
      "method" => "unknown_method"
    }

    response = @server.handle_request(request.to_json)
    
    assert_equal "2.0", response[:jsonrpc]
    assert_equal 4, response[:id]
    assert_equal(-32601, response[:error][:code])
    assert_equal "Method not found", response[:error][:message]
  end

  def test_invalid_json
    response = @server.handle_request("invalid json")
    
    assert_equal "2.0", response[:jsonrpc]
    assert_nil response[:id]
    assert_equal(-32700, response[:error][:code])
    assert_equal "Parse error", response[:error][:message]
  end

  def test_notifications_initialized
    request = {
      "jsonrpc" => "2.0",
      "method" => "notifications/initialized"
    }

    response = @server.handle_request(request.to_json)
    
    assert_nil response
  end
end