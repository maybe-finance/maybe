# config/routes/investment_analytics.rb

# This file defines routes for the Investment Analytics app.
# It is loaded conditionally if the app is enabled.

Maybe::Application.routes.draw do
  namespace :investment_analytics do
    resources :dashboards, only: [:index] do
      collection do
        get :portfolio_summary
        get :dividend_forecast
      end
    end
  end
end
