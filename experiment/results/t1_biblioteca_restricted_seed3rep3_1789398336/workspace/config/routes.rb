Rails.application.routes.draw do
  resources :books
  resources :authors

  root 'books#index'
end
