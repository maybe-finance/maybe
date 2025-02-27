Rails.application.routes.draw do
  # MFA routes
  resource :mfa, controller: "mfa", only: [ :new, :create ] do
    get :verify
    post :verify, to: "mfa#verify_code"
    delete :disable
  end

  mount GoodJob::Engine => "good_job"

  get "changelog", to: "pages#changelog"
  get "feedback", to: "pages#feedback"
  get "early-access", to: "pages#early_access"

  resource :registration, only: %i[new create]
  resources :sessions, only: %i[new create destroy]
  resource :password_reset, only: %i[new create edit update]
  resource :password, only: %i[edit update]
  resource :email_confirmation, only: :new

  resources :users, only: %i[update destroy] do
    delete :reset, on: :member
  end

  resource :onboarding, only: :show do
    collection do
      get :profile
      get :preferences
    end
  end

  namespace :settings do
    resource :profile, only: [ :show, :destroy ]
    resource :preferences, only: :show
    resource :hosting, only: %i[show update] do
      delete :clear_cache, on: :collection
    end
    resource :billing, only: :show
    resource :security, only: :show
  end

  resource :subscription, only: %i[new show] do
    get :success, on: :collection
  end

  resources :tags, except: :show do
    resources :deletions, only: %i[new create], module: :tag
  end

  namespace :category do
    resource :dropdown, only: :show
  end

  resources :categories, except: :show do
    resources :deletions, only: %i[new create], module: :category

    post :bootstrap, on: :collection
  end

  resources :budgets, only: %i[index show edit update], param: :month_year do
    get :picker, on: :collection

    resources :budget_categories, only: %i[index show update]
  end

  resources :merchants, only: %i[index new create edit update destroy]

  resources :transfers, only: %i[new create destroy show update]

  resources :imports, only: %i[index new show create destroy] do
    post :publish, on: :member
    put :revert, on: :member

    resource :upload, only: %i[show update], module: :import
    resource :configuration, only: %i[show update], module: :import
    resource :clean, only: :show, module: :import
    resource :confirm, only: :show, module: :import

    resources :rows, only: %i[show update], module: :import
    resources :mappings, only: :update, module: :import
  end

  resources :accounts, only: %i[index new] do
    collection do
      post :sync_all
    end

    member do
      post :sync
      get :chart
      get :sparkline
    end
  end

  resources :accountable_sparklines, only: :show, param: :accountable_type

  namespace :account do
    resources :holdings, only: %i[index new show destroy]

    resources :transactions, only: %i[show new create update destroy] do
      resource :transfer_match, only: %i[new create]
      resource :category, only: :update, controller: :transaction_categories

      collection do
        post "bulk_delete"
        get "bulk_edit"
        post "bulk_update"
        post "mark_transfers"
        post "unmark_transfers"
      end
    end

    resources :valuations, only: %i[show new create update destroy]
    resources :trades, only: %i[show new create update destroy]
  end

  direct :account_entry do |entry, options|
    if entry.new_record?
      route_for "account_#{entry.entryable_name.pluralize}", options
    else
      route_for entry.entryable_name, entry, options
    end
  end

  resources :transactions, only: :index do
    collection do
      delete :clear_filter
    end
  end

  # Convenience routes for polymorphic paths
  # Example: account_path(Account.new(accountable: Depository.new)) => /depositories/123
  direct :account do |model, options|
    route_for model.accountable_name, model, options
  end
  direct :edit_account do |model, options|
    route_for "edit_#{model.accountable_name}", model, options
  end

  resources :depositories, except: :index
  resources :investments, except: :index
  resources :properties, except: :index
  resources :vehicles, except: :index
  resources :credit_cards, except: :index
  resources :loans, except: :index
  resources :cryptos, except: :index
  resources :other_assets, except: :index
  resources :other_liabilities, except: :index

  resources :securities, only: :index

  resources :invite_codes, only: %i[index create]

  resources :issues, only: :show

  namespace :issue do
    resources :exchange_rate_provider_missings, only: :update
  end

  resources :invitations, only: [ :new, :create, :destroy ] do
    get :accept, on: :member
  end

  # For managing self-hosted upgrades and release notifications
  resources :upgrades, only: [] do
    member do
      post :acknowledge
      post :deploy
    end
  end

  resources :currencies, only: %i[show]

  resources :impersonation_sessions, only: [ :create ] do
    post :join, on: :collection
    delete :leave, on: :collection

    member do
      put :approve
      put :reject
      put :complete
    end
  end

  resources :plaid_items, only: %i[create destroy] do
    member do
      post :sync
    end
  end

  namespace :webhooks do
    post "plaid"
    post "plaid_eu"
    post "stripe"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "pages#dashboard"
end
