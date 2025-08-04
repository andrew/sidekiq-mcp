# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sidekiq/mcp"
require "sidekiq"
require "sidekiq/testing"
require "rack/test"

require "minitest/autorun"

Sidekiq::Testing.fake!
