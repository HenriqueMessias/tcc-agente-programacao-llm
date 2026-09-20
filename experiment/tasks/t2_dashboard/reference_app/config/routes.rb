Rails.application.routes.draw do
  root "dashboard#show"
  get "dashboard", to: "dashboard#show"
end
