# Sidekiq MCP

[![Gem Version](https://badge.fury.io/rb/sidekiq-mcp.svg)](https://badge.fury.io/rb/sidekiq-mcp)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/andrew/sidekiq-mcp/blob/main/LICENSE)

A Sidekiq plugin that provides an MCP (Model Context Protocol) server, enabling LLMs to interact with Sidekiq queues, statistics, and failed jobs through a standardized interface.

## Available Tools

The MCP server provides the following tools:

### Statistics & Monitoring
- `sidekiq_stats` - Get general Sidekiq statistics (processed, failed, busy, enqueued counts)
- `job_class_stats` - Breakdown of job counts, retries, and error rates by class
- `workers_count` - Show how many workers are running and busy
- `queue_health` - Heuristics on whether queues are backed up or healthy

### Queue Inspection  
- `list_queues` - List all queues with sizes and latency
- `queue_details` - Get detailed info about a specific queue including jobs
- `busy_workers` - List currently busy workers and their job details

### Job Management
- `failed_jobs` - List failed jobs with error details
- `list_retry_jobs` - List jobs in the retry set (jobs that failed but will be retried)
- `list_scheduled_jobs` - List jobs in the scheduled set
- `dead_jobs` - Show jobs in the dead set (jobs that have exhausted all retries)
- `job_details` - Show args, error message, and history for a job by JID

### Job Actions
- `retry_job` - Retry a failed job by JID
- `delete_failed_job` - Delete a failed job by JID  
- `remove_job` - Remove a job from any set (queue/schedule/retry/dead) by JID
- `reschedule_job` - Reschedule a job in the scheduled set to a new time
- `kill_job` - Move a job from retry/scheduled set to the dead set
- `clear_queue` - Clear all jobs from a specific queue (destructive operation)

### Real-time Monitoring
- `stream_stats` - Start streaming real-time Sidekiq statistics (use with SSE)
- `process_set` - Get detailed information about all Sidekiq processes/workers


## Example Prompts

Once configured, you can ask your LLM:

- "What's the current status of Sidekiq?"
- "Show me the failed jobs and their error messages"
- "List all queues and their health status"
- "Which job classes have the highest error rates?"
- "Show me details for job abc123"
- "Retry the job with JID abc123"
- "What jobs are currently running?"
- "Are any queues backed up or unhealthy?"
- "How many workers are busy right now?"
- "Clear all jobs from the 'low_priority' queue"
- "Reschedule job abc123 to run tomorrow at 9 AM"
- "Move this failed job to the dead set"
- "Start streaming live stats updates"

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-mcp'
```

And then execute:
```bash
bundle install
```

## Usage

### Rails Integration

The gem automatically integrates with Rails applications. Configure it in an initializer:

```ruby
# config/initializers/sidekiq_mcp.rb
Sidekiq::Mcp.configure do |config|
  config.enabled = true
  config.path = "/sidekiq-mcp"
  config.auth_token = Rails.application.credentials.sidekiq_mcp_token
  config.sse_enabled = true # Enable Server-Sent Events for real-time updates
end
```

The MCP server will be available at the configured path (default: `/sidekiq-mcp`).

### Manual Setup (Non-Rails)

For non-Rails applications, add the middleware to your Rack stack:

```ruby
require 'sidekiq/mcp'

# Configure
Sidekiq::Mcp.configure do |config|
  config.auth_token = "your-secret-token"
end

# Add to your config.ru or middleware stack
use Sidekiq::Mcp::Middleware
```

### Authentication

The MCP server supports two authentication methods:

1. **Bearer Token**: Include `Authorization: Bearer your-token` header
2. **HTTP Basic Auth**: Use any username with your token as the password

Example configuration for different MCP clients:

#### Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "sidekiq": {
      "command": "curl",
      "args": [
        "-X", "POST",
        "-H", "Content-Type: application/json",
        "-H", "Authorization: Bearer your-secret-token",
        "http://localhost:3000/sidekiq-mcp"
      ]
    }
  }
}
```

#### VS Code with Claude Extension

Configure in your VS Code settings:

```json
{
  "claude.mcpServers": {
    "sidekiq": {
      "url": "http://localhost:3000/sidekiq-mcp",
      "headers": {
        "Authorization": "Bearer your-secret-token"
      }
    }
  }
}
```

#### Cursor

Add to your Cursor configuration:

```json
{
  "mcp": {
    "servers": {
      "sidekiq": {
        "command": ["curl"],
        "args": [
          "-X", "POST",
          "-H", "Content-Type: application/json", 
          "-H", "Authorization: Bearer your-secret-token",
          "http://localhost:3000/sidekiq-mcp"
        ]
      }
    }
  }
}
```

#### Claude Code

Configure via CLI:

```bash
claude mcp add --transport http sidekiq-mcp-server http://localhost:3000/sidekiq-mcp
```

Or add to your MCP configuration:

```json
{
  "sidekiq-mcp": {
    "endpoint": "http://localhost:3000/sidekiq-mcp",
    "auth": {
      "type": "bearer",
      "token": "your-secret-token"
    }
  }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

The `example/` directory contains a sample Rails application demonstrating the integration.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andrew/sidekiq-mcp.

## License

The gem is available as open source under the terms of the MIT License.
