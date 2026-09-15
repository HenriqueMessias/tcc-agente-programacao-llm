Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index", as: :dashboard
  root to: "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
