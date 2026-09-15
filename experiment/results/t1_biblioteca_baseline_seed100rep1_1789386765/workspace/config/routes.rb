Rails.application.routes.draw do
  resources :books
  resources :authors

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "books#index"
end
