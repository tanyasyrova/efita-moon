Rails.application.routes.draw do
  root "public_pages#home"

  get "about", to: "public_pages#about", as: :about
  get "catalog", to: "catalog#index", as: :catalog
  get "catalog/:slug", to: "categories#show", as: :catalog_category

  resources :products, only: :show, param: :slug

  namespace :admin do
    root "products#index"

    resources :products, except: :show
    resources :categories, except: :show
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
