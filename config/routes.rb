Rails.application.routes.draw do
  resources :stored_images
  resources :users do
    resources :stored_images
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
