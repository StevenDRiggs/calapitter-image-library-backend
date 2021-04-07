Rails.application.routes.draw do
  resources :stored_images
  resources :users do
    resources :stored_images
  end

  post '/signup', to: 'users#create'
  post '/login', to: 'users#login'
  post '/logout', to: 'users#logout'

  post 'test_auth_header', to: 'application#test_auth_header'
  post 'test_decoded_token', to: 'application#test_decoded_token'
end
