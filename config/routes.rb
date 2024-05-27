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

  resources :imports, except: :show do
    member do
      get "load"
      patch "load" => "imports#load_csv"

      get "configure"
      patch "configure" => "imports#update_mappings"

      get "clean"
      patch "clean" => "imports#update_csv"

      get "confirm"
      patch "confirm" => "imports#publish"
    end
  end

  resources :tags, except: %i[ show destroy ] do
    resources :deletions, only: %i[ new create ], module: :tags
  end

  resources :transactions do
    collection do
      match "search" => "transactions#search", via: %i[ get post ]

      scope module: :transactions, as: :transaction do
        resources :categories do
          resources :deletions, only: %i[ new create ], module: :categories
          collection do
            resource :dropdown, only: :show, module: :categories, as: :category_dropdown
          end
        end

        resources :rules, only: %i[ index ]
        resources :merchants, only: %i[ index new create edit update destroy ]
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
