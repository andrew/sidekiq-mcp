Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Demo endpoints for testing Sidekiq jobs
  post "demo/enqueue" => "demo#enqueue_job"
  post "demo/create_jobs" => "demo#create_jobs"

  # Defines the root path route ("/")
  # root "posts#index"
end
