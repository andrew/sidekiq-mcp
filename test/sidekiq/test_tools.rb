# frozen_string_literal: true

require "test_helper"

class TestTools < Minitest::Test
  def setup
    @tools = Sidekiq::Mcp::ToolsRegistry.new
    Sidekiq::Testing.inline!
  end

  def teardown
    Sidekiq::Testing.fake!
  end

  def test_list_returns_all_tools
    tools = @tools.list
    
    assert_instance_of Array, tools
    assert tools.length > 0
    
    tool_names = tools.map { |t| t[:name] }
    expected_tools = %w[
      sidekiq_stats list_queues queue_details failed_jobs
      busy_workers retry_job delete_failed_job
    ]
    
    expected_tools.each do |tool_name|
      assert_includes tool_names, tool_name
    end
  end

  def test_sidekiq_stats_call
    result = @tools.call("sidekiq_stats", {})
    
    assert_instance_of String, result
    stats = JSON.parse(result)
    
    assert_includes stats.keys, "processed"
    assert_includes stats.keys, "failed"
    assert_includes stats.keys, "busy"
    assert_includes stats.keys, "enqueued"
  end

  def test_list_queues_call
    result = @tools.call("list_queues", {})
    
    assert_instance_of String, result
    queues = JSON.parse(result)
    
    assert_instance_of Array, queues
  end

  def test_queue_details_call
    result = @tools.call("queue_details", { "queue_name" => "default", "limit" => 5 })
    
    assert_instance_of String, result
    details = JSON.parse(result)
    
    assert_equal "default", details["queue_name"]
    assert_includes details.keys, "size"
    assert_includes details.keys, "jobs"
  end

  def test_failed_jobs_call
    result = @tools.call("failed_jobs", { "limit" => 10 })
    
    assert_instance_of String, result
    failed = JSON.parse(result)
    
    assert_includes failed.keys, "total_size"
    assert_includes failed.keys, "jobs"
    assert_instance_of Array, failed["jobs"]
  end

  def test_busy_workers_call
    result = @tools.call("busy_workers", {})
    
    assert_instance_of String, result
    workers = JSON.parse(result)
    
    assert_instance_of Array, workers
  end

  def test_unknown_tool
    result = @tools.call("unknown_tool", {})
    
    assert_equal "Unknown tool: unknown_tool", result
  end

  def test_retry_job_not_found
    result = @tools.call("retry_job", { "jid" => "nonexistent" })
    
    assert_includes result, "not found"
  end

  def test_delete_failed_job_not_found
    result = @tools.call("delete_failed_job", { "jid" => "nonexistent" })
    
    assert_includes result, "not found"
  end
end