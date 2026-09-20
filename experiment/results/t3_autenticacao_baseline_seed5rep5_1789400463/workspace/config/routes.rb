Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Autenticação
  get  "signup" => "users#new",    as: :signup
  post "signup" => "users#create"

  get    "login"  => "sessions#new",     as: :login
  post   "login"  => "sessions#create"
  delete "logout" => "sessions#destroy", as: :logout

  # Página protegida
  get "protected" => "protected#show", as: :protected

  root "sessions#new"
end
