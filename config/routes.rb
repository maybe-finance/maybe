Rails.application.routes.draw do
  resource :registration
  resource :session
  resource :password_reset
  resource :password

  resources :accounts

  scope "accounts/new" do
    scope "bank" do
      get "", to: "accounts#new_bank", as: "new_bank"
    end

    scope "credit" do
      get "", to: "accounts#new_credit", as: "new_credit"
    end
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
