Rails.application.routes.draw do
  mount GoodJob::Engine => "jobs"

  get "changelog" => "pages#changelog", as: :changelog
  get "feedback" => "pages#feedback", as: :feedback

  resource :registration
  resource :session
  resource :password_reset
  resource :password

  namespace :help do
    resources :articles, only: :show
  end

  namespace :settings do
    resource :profile, only: %i[show update destroy]
    resource :preferences, only: %i[show update]
    resource :hosting, only: %i[show update] do
      post :send_test_email, on: :collection
    end
  end

  resources :imports, except: :show do
    member do
      get "load"
      patch "load" => "imports#load_csv"
      patch "upload" => "imports#upload_csv"

      get "configure"
      patch "configure" => "imports#update_mappings"

      get "clean"
      patch "clean" => "imports#update_csv"

      get "confirm"
      patch "confirm" => "imports#publish"
    end
  end

  resources :tags, except: %i[show destroy] do
    resources :deletions, only: %i[new create], module: :tag
  end

  namespace :category do
    resource :dropdown, only: :show
  end

  resources :categories do
    resources :deletions, only: %i[new create], module: :category
  end

  resources :merchants, only: %i[index new create edit update destroy]

  namespace :account do
    resources :transfers, only: %i[new create destroy]
  end

  resources :accounts do
    collection do
      get :summary
      get :list
      post :sync_all
    end

    member do
      post :sync
    end

    scope module: :account do
      resource :logo, only: :show

      resources :holdings, only: %i[index new show]
      resources :cashes, only: :index

      resources :transactions, only: %i[index update]
      resources :valuations, only: %i[index new create]
      resources :trades, only: %i[index new create]

      resources :entries, only: %i[edit update show destroy]
    end
  end

  resources :properties, only: %i[create update]
  resources :vehicles, only: %i[create update]

  resources :transactions, only: %i[index new create] do
    collection do
      post "bulk_delete"
      get "bulk_edit"
      post "bulk_update"
      post "mark_transfers"
      post "unmark_transfers"
      get "rules"
    end
  end

  resources :institutions, except: %i[index show] do
    post :sync, on: :member
  end

  resources :issues, only: :show

  namespace :issue do
    resources :exchange_rate_provider_missings, only: :update
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
