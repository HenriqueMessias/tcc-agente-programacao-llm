Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  get    "/signup", to: "users#new",        as: :signup
  post   "/signup", to: "users#create"

  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"

  delete "/logout", to: "sessions#destroy", as: :logout

  get    "/protected", to: "protected#show", as: :protected

  root "sessions#new"
end
