Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"
  root to: "dashboard#index"
end
