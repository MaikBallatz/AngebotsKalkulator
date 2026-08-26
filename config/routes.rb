Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Your first real resource replaces this later.
  root "home#index"

  resources :consultants, only: [:index, :new, :create] do
    patch :deactivate, on: :member
  end

  resources :quotes, only: [:index, :new, :create, :show] do
    post :deliver_word, on: :member
    get :upload, on: :member
    post :upload, on: :member
  end

  get "design", to: "design#index"
  get "flow", to: "flow#index"
end
