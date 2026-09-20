Rails.application.routes.draw do
  root "books#index"
  resources :authors, except: [:show]
  resources :books, except: [:show]
end
