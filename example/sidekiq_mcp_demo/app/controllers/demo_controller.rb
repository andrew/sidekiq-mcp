# frozen_string_literal: true

class DemoController < ApplicationController
  def enqueue_job
    name = params[:name] || "test"
    times = params[:times] || 3
    
    DemoJob.perform_async(name, times)
    
    render json: { message: "Job enqueued", name: name, times: times }
  end

  def create_jobs
    # Create various jobs for testing
    DemoJob.perform_async("quick", 1)
    DemoJob.perform_async("medium", 5)
    DemoJob.perform_async("long", 10)
    DemoJob.perform_async("error", 1) # This might fail
    
    # Schedule some jobs for the future
    DemoJob.perform_in(30.seconds, "scheduled", 2)
    DemoJob.perform_in(1.minute, "delayed", 3)
    
    render json: { message: "Demo jobs created" }
  end
end