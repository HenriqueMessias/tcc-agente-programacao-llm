Rails.application.routes.draw do
  # Autenticação
  get  "/signup", to: "users#new",     as: :signup
  post "/signup", to: "users#create"

  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # Página protegida
  get "/protected", to: "protected#show", as: :protected

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "protected#show"
end
