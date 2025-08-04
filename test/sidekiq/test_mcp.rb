# frozen_string_literal: true

require "test_helper"

class Sidekiq::TestMcp < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Sidekiq::Mcp::VERSION
  end

  def test_configuration
    Sidekiq::Mcp.configure do |config|
      config.enabled = false
      config.path = "/custom-path"
      config.auth_token = "test-token"
    end

    config = Sidekiq::Mcp.configuration
    assert_equal false, config.enabled
    assert_equal "/custom-path", config.path
    assert_equal "test-token", config.auth_token
  end

  def test_default_configuration
    config = Sidekiq::Mcp::Configuration.new
    assert_equal true, config.enabled
    assert_equal "/sidekiq-mcp", config.path
    assert_nil config.auth_token
  end
end
