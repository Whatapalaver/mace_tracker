Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :exercises, only: [ :index, :new, :create ]

  resources :benchmark_presets, only: [ :index, :new, :create ]

  resources :sessions, only: [ :new, :create, :show ] do
    resources :session_sets, only: [ :new, :create ]
  end

  get "stats" => "stats#show", as: :stats

  resources :share_links, only: [ :index, :new, :create, :destroy ] do
    member do
      patch :regenerate
    end
  end

  get "shared/:token" => "shared_dashboards#show", as: :shared_dashboard

  # Defines the root path route ("/")
  root "sessions#new"
end
