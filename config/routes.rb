Rails.application.routes.draw do
  mount GoodJob::Engine => "jobs"

  get "changelog" => "pages#changelog", as: :changelog
  get "feedback" => "pages#feedback", as: :feedback
  get "invites" => "pages#invites", as: :invites

  resource :registration
  resource :session
  resource :password_reset
  resource :password

  namespace :settings do
    resource :profile, only: %i[show update destroy]
    resource :preferences, only: %i[show update]
    resource :notifications, only: %i[show update]
    resource :billing, only: %i[show update]
    resource :hosting, only: %i[show update] do
      post :send_test_email, on: :collection
    end
    resource :security, only: %i[show update]
  end

  resources :imports do
    member do
      get "select-account", to: "imports/steps#select_account", as: :select_account_for
      get "load-data", to: "imports/steps#load_data", as: :load_data_for
      get "configure", to: "imports/steps#configure"
      get "clean", to: "imports/steps#clean"
      get "confirm", to: "imports/steps#confirm"
    end
  end

  resources :transactions do
    match "search" => "transactions#search", on: :collection, via: [:get, :post], as: :search

    collection do
      scope module: :transactions do
        resources :categories, as: :transaction_categories do
          resources :deletions, only: %i[ new create ], module: :categories
        end

        resources :rules, only: %i[ index ], as: :transaction_rules
        resources :merchants, only: %i[ index new create edit update destroy ], as: :transaction_merchants
      end
    end
  end

  resources :accounts, shallow: true do
    get :summary, on: :collection
    get :list, on: :collection
    post :sync, on: :member
    resource :logo, only: %i[show], module: :accounts
    resources :valuations
  end

  # For managing self-hosted upgrades and release notifications
  resources :upgrades, only: [] do
    member do
      post :acknowledge
      post :deploy
    end
  end

  resources :currencies, only: %i[show]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "pages#dashboard"
end
