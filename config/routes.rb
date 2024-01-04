require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  # Routes for accounts
  resources :accounts do
    collection do
      get 'assets'
      get 'cash'
      get 'investments'
      get 'debts'
      get 'net_worth'
      get 'credit'
    end
  end

  resources :onboarding

  scope 'accounts/new' do
    scope 'bank' do
      get '', to: 'accounts#new_bank', as: 'new_bank'
      get 'manual', to: 'accounts#new_bank_manual', as: 'new_bank_manual'
    end

    scope 'investment' do
      get '', to: 'accounts#new_investment', as: 'new_investment'
      get 'position', to: 'accounts#new_investment_position', as: 'new_investment_position'
      get 'balance', to: 'accounts#new_investment_balance', as: 'new_investment_balance'
      get 'select_holding', to: 'accounts#select_holding', as: 'select_holding'
    end

    scope 'credit' do
      get '', to: 'accounts#new_credit', as: 'new_credit'
      get 'manual', to: 'accounts#new_credit_manual', as: 'new_credit_manual'
    end

    scope 'real-estate' do
      get '', to: 'accounts#new_real_estate', as: 'new_real_estate'
    end
  end

  resources :connections
  resources :conversations
  resources :prompts
  resources :families
  resources :holdings

  get 'settings', to: 'pages#settings', as: 'settings'
  get 'upgrade', to: 'pages#upgrade', as: 'upgrade'
  get 'advisor', to: 'pages#advisor', as: 'advisor'
  
  devise_for :users, controllers: { registrations: 'users/registrations' }

  # Routes for api
  namespace :api do
    post 'plaid/exchange_public_token', to: 'plaid#exchange_public_token'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "pages#index"
end
