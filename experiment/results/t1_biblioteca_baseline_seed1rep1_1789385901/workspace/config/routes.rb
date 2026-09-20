Rails.application.routes.draw do
  resources :books
  resources :authors

  root "books#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
