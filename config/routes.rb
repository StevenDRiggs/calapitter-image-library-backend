Rails.application.routes.draw do
  resources :stored_images
  resources :users do
    resources :stored_images
  end

  post '/signup', to: 'users#create'
  post '/login', to: 'users#login'
end
