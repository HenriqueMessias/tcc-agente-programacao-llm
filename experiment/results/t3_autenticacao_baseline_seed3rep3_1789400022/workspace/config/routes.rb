Rails.application.routes.draw do
  root "pages#home"

  get  "signup", to: "users#new", as: :signup
  post "signup", to: "users#create"

  get  "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"

  delete "logout", to: "sessions#destroy", as: :logout

  get "protected", to: "pages#protected", as: :protected

  get "up" => "rails/health#show", as: :rails_health_check
end
