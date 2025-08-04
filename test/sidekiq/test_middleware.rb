# frozen_string_literal: true

require "test_helper"

class TestMiddleware < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      use Sidekiq::Mcp::Middleware
      run ->(env) { [200, {}, ["OK"]] }
    end
  end

  def setup
    Sidekiq::Mcp.configure do |config|
      config.path = "/sidekiq-mcp"
      config.auth_token = "test-token"
    end
  end

  def test_non_mcp_request_passes_through
    get "/other-path"
    assert_equal 200, last_response.status
    assert_equal "OK", last_response.body
  end

  def test_mcp_request_without_auth_returns_401
    post "/sidekiq-mcp", {}.to_json
    assert_equal 401, last_response.status
  end

  def test_mcp_request_with_bearer_token
    request = {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "initialize"
    }

    header "Authorization", "Bearer test-token"
    header "Content-Type", "application/json"
    post "/sidekiq-mcp", request.to_json

    assert_equal 200, last_response.status
    assert_equal "application/json", last_response.content_type
    
    response = JSON.parse(last_response.body)
    assert_equal "2.0", response["jsonrpc"]
  end

  def test_mcp_request_with_basic_auth
    request = {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "initialize"
    }

    # Base64 encode "user:test-token"
    encoded = Base64.strict_encode64("user:test-token")
    header "Authorization", "Basic #{encoded}"
    header "Content-Type", "application/json"
    post "/sidekiq-mcp", request.to_json

    assert_equal 200, last_response.status
  end

  def test_mcp_request_with_wrong_token
    request = {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "initialize"
    }

    header "Authorization", "Bearer wrong-token"
    header "Content-Type", "application/json"
    post "/sidekiq-mcp", request.to_json

    assert_equal 401, last_response.status
  end

  def test_get_request_returns_405
    header "Authorization", "Bearer test-token"
    get "/sidekiq-mcp"
    
    assert_equal 405, last_response.status
  end

  def test_no_auth_required_when_no_token_configured
    Sidekiq::Mcp.configure do |config|
      config.auth_token = nil
    end

    request = {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "initialize"
    }

    header "Content-Type", "application/json"
    post "/sidekiq-mcp", request.to_json

    assert_equal 200, last_response.status
  end
end