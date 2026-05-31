Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Logged-in landing page (the store dashboard)
  root "dashboard#show"

  resources :products

  # Public storefront (no login; tenant comes from the URL slug)
  scope path: "s", module: "storefront", as: "storefront" do
    get ":store_slug", to: "stores#show", as: :store
    post ":store_slug/orders", to: "orders#create", as: :store_orders
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
