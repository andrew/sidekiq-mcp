# frozen_string_literal: true

class DemoJob < ApplicationJob
  queue_as :default

  def perform(name, times = 1)
    times.to_i.times do |i|
      Rails.logger.info "DemoJob running for #{name}, iteration #{i + 1}"
      sleep 1
    end
    
    # Simulate occasional failures for testing
    raise "Simulated error!" if name == "error" && rand < 0.5
    
    Rails.logger.info "DemoJob completed for #{name}"
  end
end