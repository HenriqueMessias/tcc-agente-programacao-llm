Rails.application.routes.draw do
  resources :books
  resources :authors

  get "up" => "rails/health#show", as: :rails_health_check

  root "books#index"
end
